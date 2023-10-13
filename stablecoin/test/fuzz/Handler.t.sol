// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    address weth;
    address wbtc;
    uint256 public mintCount;
    uint256 public redeemCount;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        engine = _dscEngine;
        dsc = _dsc;
        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = collateralTokens[0];
        wbtc = collateralTokens[1];
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        address collateral = _getCollateralFromSeed(collateralSeed);
        vm.startPrank(msg.sender);
        ERC20Mock(collateral).mint(msg.sender, amountCollateral);
        ERC20Mock(collateral).approve(address(engine), amountCollateral);
        engine.depositCollateral(collateral, amountCollateral);
        vm.stopPrank();
    }

    function mint(uint256 amount, uint256 collateralSeed, uint256 amountCollateral) public {
        depositCollateral(collateralSeed, amountCollateral);
        (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = engine.getUserInformation(msg.sender);
        int256 maxDscToMint = int256((totalCollateralValueInUsd / 2) - totalDscMinted);
        if (maxDscToMint < 0) {
            return;
        }
        amount = bound(amount, 1, uint256(maxDscToMint));
        vm.prank(msg.sender);
        engine.mintDsc(amount);
        mintCount++;
    }

    function redeemCollateral(uint256 collateralSeed, uint256 collateralAmount) public {
        // depositCollateral(collateralSeed, collateralAmount);
        address collateral = _getCollateralFromSeed(collateralSeed);
        vm.startPrank(msg.sender);
        uint256 maxCollateralToRedeem = engine.getCollateralBalanceOfUser(msg.sender, collateral);
        collateralAmount = bound(collateralAmount, 0, maxCollateralToRedeem);
        if (collateralAmount == 0) {
            return;
        }
        engine.redeemCollateral(collateral, collateralAmount);
        vm.stopPrank();
        redeemCount++;
    }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (address) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
