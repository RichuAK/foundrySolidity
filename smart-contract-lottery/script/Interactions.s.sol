// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    // The function that runs
    function run() external returns (uint64) {
        return createSubsciptionUsingConfig();
    }

    function createSubsciptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , ) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating Subscription on chain id: ", block.chainid);
        console.log(
            "The following bits might not work. If error, go the standard way"
        );
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(
            _vrfCoordinator
        );
        vm.startBroadcast();
        uint64 subId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        console.log("created subId: ", subId);
        return subId;
    }
}
