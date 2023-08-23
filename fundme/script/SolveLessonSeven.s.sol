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
        // consoles used for debugging
        console.log("The Data: ", privateData);
        console.log("Attempting to find Solution for Lesson Seven");
        console.log("From address: ", msg.sender);
        // sets the msg.sender as the challenge solver, instead of this contract : for _safeMint() reasons
        // broadcast instead of prank to hit the actual blockchain
        vm.broadcast(msg.sender);
        LessonSeven lessonSeven = LessonSeven(LessonSevenAddress);
        lessonSeven.solveChallenge(privateData, "richuak1");
    }

    function getPrivateData() internal view returns (uint256) {
        // vm.load() reads the storage at the given slot
        bytes32 privateVariable = vm.load(
            LessonSevenAddress,
            bytes32(uint256(777))
        );
        return uint256(privateVariable);
    }
}
