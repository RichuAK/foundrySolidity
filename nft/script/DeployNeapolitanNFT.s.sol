// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {Script} from "forge-std/Script.sol";

contract DeployNeapolitanNFT is Script {
    function run() external returns (NeapolitanNFT) {
        vm.startBroadcast();
        NeapolitanNFT neapolitanNFT = new NeapolitanNFT();
        vm.stopBroadcast();
        return neapolitanNFT;
    }
}
