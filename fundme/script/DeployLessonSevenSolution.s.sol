// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LessonSevenSolution} from "../src/LessonSevenSolution.sol";

contract DeployLessenSevenSolution is Script {
    // Just the deployment
    function run() external {
        vm.startBroadcast();
        new LessonSevenSolution();
        vm.stopBroadcast();
    }
}
