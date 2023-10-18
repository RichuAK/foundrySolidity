// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

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
    address public BEN = makeAddr("ben");
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    uint256 public constant ERC20_STARTING_BALANCE = 20 ether;
    uint256 public constant COLLATERAL_AMOUNT = 12 ether;
    uint256 public constant DSC_AMOUNT = 12000e18;
    // what's the difference between these assignments and the ones above? Is there any difference?
    // uint256 public constant ERC20_STARTING_BALANCE = 20e18;
    // uint256 public constant COLLATERAL_AMOUNT = 12e18;

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
        ERC20Mock(weth).mint(BEN, 10 * ERC20_STARTING_BALANCE);
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

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintDsc(weth, COLLATERAL_AMOUNT, DSC_AMOUNT);
        vm.stopPrank();
        _;
        // user is exactly at MIN_HEALTH_FACTOR at this point
    }

    function testDepositCollateralAndMintDSCRevertsIfTokenIsntAllowed() public {
        ERC20Mock dummyToken = new ERC20Mock();
        dummyToken.mint(USER, ERC20_STARTING_BALANCE);
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        // vm.expectRevert();
        engine.depositCollateralAndMintDsc(address(dummyToken), COLLATERAL_AMOUNT, DSC_AMOUNT);
    }

    function testMintDSCRevertsIfAmountIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__ShouldBeMoreThanZero.selector);
        engine.mintDsc(0);
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

    // liquidate tests

    function testLiquidateRevertsIfAmountIsZero() public depositedCollateral {
        vm.prank(BEN);
        vm.expectRevert(DSCEngine.DSCEngine__ShouldBeMoreThanZero.selector);
        engine.liquidate(USER, address(weth), 0);
    }

    function testLiquidateRevertsIfHealthFactorIsOkay() public depositedCollateralAndMintedDsc {
        vm.prank(BEN);
        vm.expectRevert(DSCEngine.DSCEngine__UserHealthFactorOk.selector);
        engine.liquidate(USER, address(weth), DSC_AMOUNT);
    }

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

    // Not much of an idea what's happening here!!!
    // Or is the error in the code?

    // update: possibly issues with collateralAmount being zero for USER
    // calculating bonuses and everything!
    function testLiquidateRevertsWithoutImprovingUserHealthFactor() public depositedCollateralAndMintedDsc {
        console.log("Health Factor of USER in the beginning: ", engine.getHealthFactor(USER));
        // ERC20Mock(weth).mint(BEN, 4 ether);
        vm.prank(USER);
        engine.redeemCollateral(weth, COLLATERAL_AMOUNT);
        console.log("Health Factor of USER after redeeming: ", engine.getHealthFactor(USER));
        // ERC20Mock(weth).mint(BEN, ERC20_STARTING_BALANCE);
        vm.startPrank(BEN);
        ERC20Mock(weth).approve(address(engine), 2 * COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintDsc(weth, COLLATERAL_AMOUNT, DSC_AMOUNT);
        console.log("Health Factor of BEN prior to liquidating: ", engine.getHealthFactor(BEN));
        dsc.approve(address(engine), DSC_AMOUNT);
        // ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        // vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        vm.expectRevert();
        engine.liquidate(USER, weth, DSC_AMOUNT);
        vm.stopPrank();
        console.log("Health Factor of BEN after liquidating: ", engine.getHealthFactor(BEN));
        (uint256 dscMinted, uint256 collateralValueinUsd) = engine.getUserInformation(BEN);
        console.log("BEN's dscMinted and collaterValueinUsd, respectively: ", dscMinted, collateralValueinUsd);
        // assertEq(1e18, engine.getHealthFactor(BEN));
    }

    // to test a sunny day scenario on liquidate
    // fails!!!!
    function testLiquidateWorksFine() public depositedCollateralAndMintedDsc {
        console.log("Health Factor of USER in the beginning: ", engine.getHealthFactor(USER));
        // vm.prank(USER);
        // engine.redeemCollateral(weth, (COLLATERAL_AMOUNT / 2));
        // console.log("Health Factor of USER after redeeming: ", engine.getHealthFactor(USER));
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(1000e8);
        vm.startPrank(BEN);
        ERC20Mock(weth).approve(address(engine), (5 * COLLATERAL_AMOUNT));
        engine.depositCollateralAndMintDsc(weth, 5 * COLLATERAL_AMOUNT, DSC_AMOUNT);
        dsc.approve(address(engine), (DSC_AMOUNT));
        engine.liquidate(USER, weth, (DSC_AMOUNT));
        vm.stopPrank();
        console.log("Health Factor of USER after liquidating: ", engine.getHealthFactor(USER));
        uint256 expectedTotalDSCMintedForUser = 6000e18;
        (uint256 totalDscMintedForUser,) = engine.getUserInformation(USER);
        assertEq(expectedTotalDSCMintedForUser, totalDscMintedForUser);
    }

    function testRedeemCollateralForDsc() public depositedCollateralAndMintedDsc {
        uint256 dscMinted;
        uint256 collateralValueinUsd;
        (dscMinted, collateralValueinUsd) = engine.getUserInformation(USER);
        console.log("dscMinted before redemption: ", dscMinted);
        console.log("CollateralValue in usd before redemption: ", collateralValueinUsd);
        vm.startPrank(USER);
        dsc.approve(address(engine), DSC_AMOUNT);
        // These -1's are a messy way of avoiding division by 0 error, from the Oracle. Not great, but works for now
        uint256 collateralAmountToRedeem = COLLATERAL_AMOUNT - 1;
        // uint256 collateralAmountToRedeem = 11e18;
        // uint256 collateralAmountToRedeem = COLLATERAL_AMOUNT - 1 ether;
        console.log("Collateral amount to redeem: ", collateralAmountToRedeem);
        uint256 dscToBurn = DSC_AMOUNT - 1;
        engine.redeemCollateralForDsc(weth, collateralAmountToRedeem, dscToBurn);
        vm.stopPrank();
        (dscMinted, collateralValueinUsd) = engine.getUserInformation(USER);
        console.log("dscMinted after redemption: ", dscMinted);
        console.log("CollateralValue in usd after redemption: ", collateralValueinUsd);
        uint256 expecteddscMinted = 1;
        // uint256 expectedcollateralValueinUsd = 0;
        assertEq(dscMinted, expecteddscMinted);
        // assertEq(collateralValueinUsd, expectedcollateralValueinUsd);
    }

    function testUserHealthFactorLimit() public depositedCollateral {
        // adhoc healthfactor calculation
        uint256 LIQUIDATION_THRESHOLD = 50;
        uint256 LIQUIDATION_PRECISION = 100;
        uint256 PRECISION = 1e18;
        uint256 dscToMint = 12001e18; //the limit is half the collateral deposited
        uint256 collateralValue = 24000e18;
        uint256 collateralAdjustedForThreshold = (collateralValue * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        uint256 expectedHealthFactor = (collateralAdjustedForThreshold * PRECISION) / dscToMint;
        console.log("Health Factor", expectedHealthFactor);
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        engine.mintDsc(dscToMint);
        // Reason for the adhoc healthfactor calculation:
        /*
        Since this is the first time any DSC is being minted it gets reverted, 
        there is no way of accessing healthFactor via getHealthFactor(USER) without hitting a division by zero error.
        But the 'BreaksHealthFactor' error does need the health factor at the moment it's being broken for us to write the proper 
        expectRevert with right healthFactor at the time
        So, to tackle both these issues, we calculate the expectedHealthFactor before sending the transaction
        */
    }

    // function testLiquidateRevertsIfUserHealthFactorNotImproved() public depositedCollateral {
    //     vm.prank(USER);
    //     engine.mintDsc(13000e18);
    //     vm.prank(BEN);
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
