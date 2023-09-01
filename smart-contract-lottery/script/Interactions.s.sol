// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

// import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    // The function that runs
    function run() external returns (uint64) {
        return createSubsciptionUsingConfig();
    }

    function createSubsciptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
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

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address linkToken
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address linkToken
    ) public {
        console.log("VRFCoordinator: ", vrfCoordinator);
        console.log("subId: ", subId);
        console.log("ChainID: ", block.chainid);
        if (block.chainid == 31337) {
            // if it's a local chain, i.e anvil
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        address raffleaddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        // Raffle raffle = Raffle(raffleaddress);
        addConsumerUsingConfig(raffleaddress);
    }

    function addConsumerUsingConfig(address contractaddress) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , ) = helperConfig
            .activeNetworkConfig();
        addConsumer(contractaddress, vrfCoordinator, subId);
    }

    function addConsumer(
        address raffleAddress,
        address vrfCoordinator,
        uint64 subId
    ) public {
        console.log("Adding consumer: ", raffleAddress);
        console.log("Using coordinator: ", vrfCoordinator);
        console.log("ChainID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffleAddress);
        vm.stopBroadcast();
    }
}
