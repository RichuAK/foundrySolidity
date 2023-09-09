// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract LessonNineSolution {
    function solveC() public {}
}

contract InteractWithSolution is Script {
    LessonNineSolution lessonNineSolution =
        LessonNineSolution(0x3039fA83eD7FBc842F0DD4238919e548614fa695);

    function run() external {
        console.log("Attempting to interact");
        vm.startBroadcast(msg.sender);
        lessonNineSolution.solveC();
        vm.stopBroadcast();
    }
}
