// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract GetPrivateData is Script {
    function run() external view {
        address LessonSeven = address(
            0xD7D127991c6A89Df752FC3daeC17540aE8B86101
        );
        bytes32 leet = vm.load(LessonSeven, bytes32(uint256(777)));
        console.log("Attempting to find Solution for Lesson Seven");
        console.log("The private data: %s", uint256(leet)); // 1337
    }
}
