// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address _priceFeed = helperConfig.activeNetworkConfig();

        // anytihng before Bradcast is not gonna incur gas,
        // hence the declaration and assigning of HelperCongig prior
        vm.startBroadcast();
        // not assigning the new FundMe to any fundMe variable since we're not gonna use it further
        // you just need to deploy, that's it
        FundMe fundMe = new FundMe(_priceFeed);
        // but assigning and returning in the new paradigm so it can be used in testing
        // define the rules so you can break them later, of course
        vm.stopBroadcast();
        return fundMe;
    }
}
