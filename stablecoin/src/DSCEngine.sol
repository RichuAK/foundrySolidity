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

/**
 * @title DSCEngine
 * @author Richu A Kuttikattu
 * @notice This contract is the engine of the DSC StableCoin project. It handles all the logic that ensures the 1 token == $1 peg.
 * @notice It handles minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on MakerDAO DSS system
 *
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

    //////////////////////////
    // State Variables    ////
    /////////////////////////

    /// @dev a mapping to specify the allowed tokens that can be accepted as collateral
    /// @dev rather than just an address-to-bool mapping, going directly for priceFeed since an oracle is needed anyway
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposits;
    DecentralizedStableCoin private immutable i_dsc;

    /////////////////
    // Events    ////
    /////////////////
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 indexed amount);

    /////////////////
    // Modifiers ////
    /////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__ShouldBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /////////////////
    // Functions ////
    /////////////////

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__PriceFeedsAndTokensDontHaveTheSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////////
    // External Functions ////
    //////////////////////////

    function depositCollateralAndMintDsc() external {}

    /**
     *
     * @param tokenCollateralAddress The address of the token contract whose token is to be accepted as collateral
     * @param amountCollateral The amount of collateral to deposit
     *
     * @notice follows CEI - Checks, Effects, (external) Interactions
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
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

    function liquidate() external {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function getHealthFactor() external view {}
}
