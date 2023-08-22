// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract LessonSeven {
    function solveChallenge(
        uint256 valueAtStorageLocationSevenSevenSeven,
        string memory yourTwitterHandle
    ) external {}
}

contract SolveLessonSeven is Script {
    address LessonSevenAddress =
        address(0xD7D127991c6A89Df752FC3daeC17540aE8B86101);

    function run() external {
        uint256 privateData = getPrivateData();
        console.log("The Data: ", privateData);
        console.log("Attempting to find Solution for Lesson Seven");
        console.log("From address: ", msg.sender);
        vm.prank(msg.sender);
        LessonSeven lessonSeven = LessonSeven(LessonSevenAddress);
        lessonSeven.solveChallenge(privateData, "richuak1");
    }

    function getPrivateData() internal view returns (uint256) {
        bytes32 privateVariable = vm.load(
            LessonSevenAddress,
            bytes32(uint256(777))
        );

        // console.log("The private data: ", uint256(privateVariable));
        return uint256(privateVariable);
    }
}
