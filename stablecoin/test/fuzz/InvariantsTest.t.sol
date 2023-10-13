// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

// Invariants to think about

// 1. The debt should never exceed the collateral. i.e DSCTotalSupply < TotalCollateralValueInUSD
// 2. Getter view functions should never revert (evergreen invariant).

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    DeployDSC deployer;
    HelperConfig helperConfig;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    Handler handler;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.activeNetworkConfig();
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThatTotalSupplyDollars() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(engine));
        uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getUsdValue(weth, wethDeposted);
        uint256 wbtcValue = engine.getUsdValue(wbtc, wbtcDeposited);

        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);
        console.log("total supply: ", totalSupply);
        console.log("Times mint function was called: ", handler.mintCount());
        console.log("Time Redeem Function was called successfully: ", handler.redeemCount());

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
