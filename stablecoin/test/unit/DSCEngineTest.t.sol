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

    function testDepositCollateralAndMintDSCRevertsIfTokenIsntAllowed() public {
        address dummyToken = makeAddr("token");
        uint256 collateralAmount = 500;
        uint256 dscToMint = 1000;
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        // vm.expectRevert();
        engine.depositCollateralAndMintDsc(dummyToken, collateralAmount, dscToMint);
    }

    function testMintDSCRevertsIfAmountIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__ShouldBeMoreThanZero.selector);
        engine.mintDsc(0);
    }

    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        // Act /Assert
        vm.expectEmit();
        // vm.expectEmit(user, address(weth), 17e18);
        emit CollateralDeposited(USER, address(weth), COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintDsc(weth, COLLATERAL_AMOUNT, 123);
        vm.stopPrank();
    }

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
