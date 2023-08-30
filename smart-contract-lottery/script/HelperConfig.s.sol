// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

// import {Raffle} from "../src/Raffle.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callBackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, //not provided in chainlink docs anymore?
                subscriptionId: 0, // update this with custom subId
                callBackGasLimit: 500000 // 500,000 gas, should be enough
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        } else {
            uint96 baseFee = 0.25 ether; //actually in LINK, for chainlink
            uint96 gasPriceLink = 1e9; // 1 gwei LINK, again
            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
                baseFee,
                gasPriceLink
            );
            vm.stopBroadcast();
            activeNetworkConfig = NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinatorMock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // script will add this
                callBackGasLimit: 500000 // 500,000 gas, should be enough
            });

            return activeNetworkConfig;
        }
    }

    // getSepoliaConfig, getorCreateAnvilConfig
}
