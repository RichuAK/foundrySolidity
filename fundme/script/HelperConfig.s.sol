// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

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
    }

    // the variable that's gonna store all the networkconfigs
    // declared as public so others can access the getter function
    // going to be a mock if anvil, otherwise grab addresses via chainid accordingly
    NetworkConfig public activeNetworkConfig;

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
}
