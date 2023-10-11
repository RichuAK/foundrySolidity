// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Richu A Kuttikattu
 * @notice This contract is the engine of the DSC StableCoin project. It handles all the logic that ensures the 1 token == $1 peg.
 * @notice It handles minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on MakerDAO DSS system
 *
 *
 * @dev ReentrancyGuard from openzeppelin, as a defense against reentrancy attacks
 *
 * The system is designed to be as minimal as possible.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 */
contract DSCEngine is ReentrancyGuard {
    /////////////////
    // Errors    ////
    /////////////////

    error DSCEngine__ShouldBeMoreThanZero();
    error DSCEngine__PriceFeedsAndTokensDontHaveTheSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__UserHealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    //////////////////////////
    // State Variables    ////
    /////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // math in the end comes out to 200% collateral (yep)
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // this could be 1e18. Wait and see. Update: it is
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidation

    /// @dev a mapping to specify the allowed tokens that can be accepted as collateral
    /// @dev rather than just an address-to-bool mapping, going directly for priceFeed since an oracle is needed anyway
    mapping(address token => address priceFeed) private s_priceFeeds;
    /// @dev a mapping to keep track of all the deposits of each token made by the user
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposits;
    /// @dev the DSC tokens minted by each user
    mapping(address user => uint256 DscMinted) private s_mintedDsc;
    /// @dev array of all the tokens that are being accepted as collateral
    address[] private s_collateralTokens;
    /// @dev the DecentralizedStableCoin contract with mint and burn functions, controlled by this Engine
    DecentralizedStableCoin private immutable i_dsc;

    /////////////////
    // Events    ////
    /////////////////
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed tokenAddress, uint256 amount
    );

    /////////////////
    // Modifiers ////
    /////////////////

    // modifier for a sanity check
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__ShouldBeMoreThanZero();
        }
        _;
    }

    // modifier to check whether can be allowed as a collateral
    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /////////////////
    // Functions ////
    /////////////////

    ///
    /// @param tokenAddresses the array of token addresses that are accepted as collateral
    /// @param priceFeedAddresses array of priceFeed addresses that gives the corresponding usd value of each of the collateral token
    /// @param dscAddress address of the dsc contract to be controlled by this contract
    /// @dev takes the arrays and sets a couple of state variables
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__PriceFeedsAndTokensDontHaveTheSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////////
    // External Functions ////
    //////////////////////////

    /**
     * @dev combines depositCollateral() and mintDsc() into one transaction
     * @param tokenCollateralAddress The address of the token contract whose token is to be accepted as collateral
     * @param amountCollateral The amount of collateral to deposit
     * @param dscToMint amount of DSC token to be minted, specified by the user
     */
    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 dscToMint)
        external
    {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(dscToMint);
    }

    /**
     *
     * @param tokenCollateralAddress The address of the token contract whose token is to be accepted as collateral
     * @param amountCollateral The amount of collateral to deposit
     *
     * @notice follows CEI - Checks, Effects, (external) Interactions
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposits[msg.sender][tokenCollateralAddress] += amountCollateral;

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @param dscToMint amount of DSC token to be minted. Specified by the user
     * @dev collateral should be more than the minimum threshold
     * @notice follows CEI
     */
    function mintDsc(uint256 dscToMint) public moreThanZero(dscToMint) nonReentrant {
        // (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = _getAccountInformation(user);
        s_mintedDsc[msg.sender] += dscToMint;
        _revertIfHealthFactorIsLow(msg.sender);
        bool minted = i_dsc.mint(msg.sender, dscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    // Liquidate a certain user's debt position if the health factor goes below MIN_HEALTH_FACTOR
    // Incentivize others to put in DSC by giving them bonuses
    function liquidate(address user, address collateralToken, uint256 debtToCoverInDsc)
        external
        moreThanZero(debtToCoverInDsc)
        nonReentrant
    {
        // check user's health factor before proceeding
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__UserHealthFactorOk();
        }

        uint256 tokenAmountFromDebtToCover = getTokenAmountFromUSD(collateralToken, debtToCoverInDsc);
        uint256 bonusCollateral = (tokenAmountFromDebtToCover * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION; // LIQUIDATION_PRECISION is used for the number 100
        uint256 totalCollateralToRedeem = tokenAmountFromDebtToCover + bonusCollateral;
        _redeemCollateral(user, msg.sender, collateralToken, totalCollateralToRedeem);
        _burnDsc(user, msg.sender, debtToCoverInDsc);
        uint256 userUpdatedHealthFactor = _healthFactor(user);
        if (userUpdatedHealthFactor <= userHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsLow(msg.sender);
    }

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 collateralAmount, uint256 dscAmount)
        external
    {
        // this more or less solves the issue of money getting locked in. You can burn your entire debt position and then fully redeem your collateral
        burnDsc(dscAmount);
        redeemCollateral(tokenCollateralAddress, collateralAmount);
        //no need to check healthFactor since redeemCollateral() does it in the end already
    }

    /**
     * @dev redeem the collateral that was deposited by the user
     * @dev checks the healthfactor after redemption and reverts if HealthFactor is not good
     * @param tokenCollateralAddress address of the token that's to be redeemed
     * @param collateralAmount amount to be redeemed
     *
     * @notice will be refactored later for mysterious reasons (You can't empty once you're in the system?)
     * violates CEI for better gas performance, instead of simulating the transfer first
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 collateralAmount)
        public
        moreThanZero(collateralAmount)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, collateralAmount);
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(msg.sender, msg.sender, amount);
        // this is pretty much redundant since collateral remains unchanged while debt(dsc) is reduced
        _revertIfHealthFactorIsLow(msg.sender);
    }

    //////////////////////////
    // Internal Functions ////
    //////////////////////////

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 collateralAmount)
        private
    {
        s_collateralDeposits[from][tokenCollateralAddress] -= collateralAmount;
        bool success = IERC20(tokenCollateralAddress).transfer(to, collateralAmount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        emit CollateralRedeemed(from, to, tokenCollateralAddress, collateralAmount);
    }

    /**
     * @dev low-level function, handle with care with checks and balances!
     * @param debtHolder user whose DSCs are going to be burned/taken away
     * @param liquidator user who's actually paying for the burn, by transferring DSC to the contract
     * @param amount  amount to be burned
     */
    function _burnDsc(address debtHolder, address liquidator, uint256 amount) private moreThanZero(amount) {
        s_mintedDsc[debtHolder] -= amount;
        // don't you need to approve this first?! Or is it Owner privileges?
        bool success = i_dsc.transferFrom(liquidator, address(this), amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amount);
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        totalDscMinted = s_mintedDsc[user];
        totalCollateralValueInUsd = getAccountCollateralValueInUsd(user);
    }

    /**
     * @param user the address of the user whose healthfactor needs to be checked
     * @dev returns a ratio of collaterized assets in USD vs DSC minted by the user
     * @notice if the returned value is less than 1, the user can be liquidated
     */
    function _healthFactor(address user) private view returns (uint256 healthFactor) {
        (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = _getAccountInformation(user);

        // // BUG Fix to remedy division by zero in the initial case
        // if (totalDscMinted == 0) {
        //     totalDscMinted = 20;
        // }
        uint256 collateralAdjustedForThreshold =
            (totalCollateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // up here, LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION
        // this just comes out to 50/100 = 1/2 which basically means you're cutting the health by half
        // and then basically forcing the user to collaterize more via healthfactor
        // I don't know why we're using LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION fancy terms
        healthFactor = (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // BUG: totalDscMinted for a new user is 0, so healthFactor errors with a division by Zero!!
        // maybe you don't need PRECISION here? Or do you?
    }

    function _revertIfHealthFactorIsLow(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    ///////////////////////////////
    // Public View Functions /////
    //////////////////////////////

    /**
     * @param user the address of the user whose collateral position is being queried
     * @dev returns the total Collateral Value in USD of user
     */
    function getAccountCollateralValueInUsd(address user) private view returns (uint256 totalCollateralValueInUsd) {
        address token;
        uint256 amount;
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            token = s_collateralTokens[i];
            amount = s_collateralDeposits[user][token];
            // uint256 declaration
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    /**
     * @dev takes in the token address and amount, and gives the corresponding USD value of the tokens from the Oracle
     * @param token token address whose value needs to be found out
     * @param amount amount of tokens whose value needs to be found out
     */
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // ADDITIONAL_FEED_PRECISION since price is returned in 8 decimal places. Need to get the digits right
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUSD(address token, uint256 usdValueInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdValueInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getHealthFactor(address user) public view returns (uint256) {
        return _healthFactor(user);
    }

    function getUserInformation(address user)
        public
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        return _getAccountInformation(user);
    }

    function getCollateralTokens() public view returns (address[] memory) {
        return s_collateralTokens;
    }
}
