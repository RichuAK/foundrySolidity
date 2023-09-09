// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {LessonNine} from "../test/mocks/LessonNine.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployLessonNineMock is Script {
    // address public lessonNineAddress;
    function run() external {
        vm.broadcast();
        new LessonNine();
        // LessonNine lessonNine = new LessonNine();
        // lessonNineAddress = address(lessonNine);
    }
}

contract SolveLessonNine is Script {
    // LessonNine public lessonNine;

    address public lessonNineAddress;

    LessonNine lessonNine;

    // function run() external {
    //     lessonNineAddress = DevOpsTools.get_most_recent_deployment(
    //         "LessonNine",
    //         block.chainid
    //     );
    //     solve();
    // }

    function run() external {
        // lessonNine = new LessonNine();
        // Sepolia Official Address:
        // lessonNineAddress = 0x33e1fD270599188BB1489a169dF1f0be08b83509;
        // Anvil Chain:
        lessonNineAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        solve();
    }

    function solve() public {
        uint256 guess = uint256(
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.prevrandao,
                    block.timestamp
                )
            )
        ) % 100000;
        vm.startBroadcast();
        bool guessedRight = LessonNine(lessonNineAddress).solveChallenge(guess);
        vm.stopBroadcast();
        console.log("Guess was ", guessedRight);
    }
}
