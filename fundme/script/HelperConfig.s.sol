// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
// not required. Me playing with console down there somewhere
import {console} from "forge-std/Test.sol";

contract HelperConfig is Script {
    // struct that defines the network configs
    // could be multiple variables
    struct NetworkConfig {
        address priceFeed;
    }

    // constructor gets the networkconfig based on the chainid at the time of deployment
    // this is where all the magic actually happens, the actual modularisation
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        }
        // anvil chain is 31337. Optional, since the default is an anvil deployment
        else if (block.chainid == 31337) {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    // the variable that's gonna store all the networkconfigs
    // declared as public so others can access the getter function
    // going to be a mock if anvil, otherwise grab addresses via chainid accordingly
    NetworkConfig public activeNetworkConfig;

    // numbers to be passed into the mock constructor
    // always a better convention to declare them as constants
    // rather than pass them as magic numbers. Better code maintainance
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 1800e8;

    // function that's gonna return the NetworkConfig struct for Sepolia
    // since the struct is a derived data type, notice the use of 'memory'
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });

        return sepoliaConfig;
    }

    // same as the above function, but for mainnnet
    // so on and so forth for other networks as well
    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });

        return mainnetConfig;
    }

    // networkconfig for the local anvil
    // deploys the mock and returns the address, since it's local
    // not pure, since there's a deployment and an address reading
    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // if the contract has already been deployed, just get it
        if (activeNetworkConfig.priceFeed != address(0)) {
            console.log("returning from the existing address!");
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(8, 1800e8);
        vm.stopBroadcast();
        NetworkConfig memory mockConfig = NetworkConfig({
            priceFeed: address(mock)
        });

        return mockConfig;
    }
}
