// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC public deployer;
    HelperConfig public helperConfig;
    DSCEngine public engine;
    DecentralizedStableCoin public dsc;
    address public wethUsdPriceFeed;
    address public wbtcPriceFeed;
    address public weth;
    address public wbtc;
    address public USER = makeAddr("user");
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    uint256 public constant ERC20_STARTING_BALANCE = 20 ether;
    uint256 public constant COLLATERAL_AMOUNT = 12 ether;

    // event declarations
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed tokenAddress, uint256 amount
    );

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, helperConfig) = deployer.run();
        (wethUsdPriceFeed, wbtcPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, ERC20_STARTING_BALANCE);
    }

    // Constructor Tests

    function testConstructorRevertsIfArraysAreDifferentLength() public {
        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);
        priceFeedAddresses.push(wethUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__PriceFeedsAndTokensDontHaveTheSameLength.selector);
        new DSCEngine(priceFeedAddresses, tokenAddresses, address(dsc));
    }

    /* Start of My Tests */
    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        engine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testDepositCollateralAndMintDSCRevertsIfTokenIsntAllowed() public {
        ERC20Mock dummyToken = new ERC20Mock();
        dummyToken.mint(USER, ERC20_STARTING_BALANCE);
        uint256 dscToMint = 1000;
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        // vm.expectRevert();
        engine.depositCollateralAndMintDsc(address(dummyToken), COLLATERAL_AMOUNT, dscToMint);
    }

    function testMintDSCRevertsIfAmountIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__ShouldBeMoreThanZero.selector);
        engine.mintDsc(0);
    }

    // someone can mint a ridiculous amount of dsc at their initial mint after collateralizing a trivial amount of tokens
    // think about this
    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        // Act /Assert
        vm.expectEmit();
        // vm.expectEmit(user, address(weth), 17e18);
        emit CollateralDeposited(USER, address(weth), COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintDsc(weth, COLLATERAL_AMOUNT, 135);
        vm.stopPrank();
    }

    // The expect emit path fails, since there's a Transfer emit being emitted?
    // But the expectedCollateralValue approach succeeds
    function testRedeemCollateral() public depositedCollateral {
        uint256 expectedCollateralValueInUsd = 0;
        uint256 collateralValueInUsd;
        vm.prank(USER);
        // vm.expectEmit();
        engine.redeemCollateral(weth, COLLATERAL_AMOUNT);
        (, collateralValueInUsd) = engine.getUserInformation(USER);
        // emit CollateralRedeemed(USER, USER, weth, COLLATERAL_AMOUNT);
        assertEq(expectedCollateralValueInUsd, collateralValueInUsd);
    }

    function testMintDsc() public depositedCollateral {
        uint256 expectedDscMinted = 11000;
        uint256 expectedCollateralValueInUsd = 24000e18;
        uint256 dscMinted;
        uint256 collateralValueInUsd;
        vm.prank(USER);
        engine.mintDsc(11000);
        (dscMinted, collateralValueInUsd) = engine.getUserInformation(USER);
        assertEq(expectedDscMinted, dscMinted);
        assertEq(expectedCollateralValueInUsd, collateralValueInUsd);
    }

    // function testInitialMintDsc() public {
    //     uint256 expectedDscMinted = 1e25 ether;
    //     uint256 dscMinted;
    //     vm.prank(USER);
    //     engine.mintDsc(expectedDscMinted);
    //     (dscMinted,) = engine.getUserInformation(USER);
    //     assertEq(expectedDscMinted, dscMinted);
    // }

    function testMintDscRevertsIfHealthFactorBreaks() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        engine.mintDsc(1);
    }

    // Reduntant, sorta
    // function testGetUserInformation() public depositedCollateral {
    //     uint256 expectedDscMinted = 0;
    //     uint256 expectedCollateralValueInUsd = 24000e18;
    //     uint256 dscMinted;
    //     uint256 collateralValueInUsd;
    //     (dscMinted, collateralValueInUsd) = engine.getUserInformation(USER);
    //     assertEq(expectedDscMinted, dscMinted);
    //     assertEq(expectedCollateralValueInUsd, collateralValueInUsd);
    // }

    /* End of My Tests */

    // All this tests are for local environment at the moment

    //Price Tests

    function testGetUsdValue() public view {
        //Arrange
        uint256 eth = 20 ether;
        uint256 expectedUsdValue = 40000e18;
        //Act
        uint256 recievedUsValue = engine.getUsdValue(weth, eth);
        //Assert
        assert(expectedUsdValue == recievedUsValue);
    }

    // Deposit Collateral Tests

    function testDepositCollateral() public {
        // Arrange
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        // Act /Assert
        vm.expectEmit();
        // vm.expectEmit(user, address(weth), 17e18);
        emit CollateralDeposited(USER, address(weth), COLLATERAL_AMOUNT);
        engine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }
}
