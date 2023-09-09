// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LessonNineSolution} from "../src/LessonNineSolution.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract DeployLessonNineSolution is Script {
    function run() external {
        vm.broadcast();
        new LessonNineSolution();
    }
}

contract SolveLessonNine is Script {
    address lessonNineSolutionAddress =
        0x512850F3D2Fd976835C7a9EA75f8a69D62518374;

    function run() external {
        // lessonNineSolutionAddress = DevOpsTools.get_most_recent_deployment(
        //     "LessonNineSolution",
        //     block.chainid
        // );
        vm.startBroadcast();
        LessonNineSolution(lessonNineSolutionAddress).solve();
        vm.stopBroadcast();
    }
}

contract TransferNFTToDeployer is Script {
    address lessonNineSolutionAddress =
        0x512850F3D2Fd976835C7a9EA75f8a69D62518374;

    function run() external {
        // lessonNineSolutionAddress = DevOpsTools.get_most_recent_deployment(
        //     "LessonNineSolution",
        //     block.chainid
        // );
        vm.broadcast();
        LessonNineSolution(lessonNineSolutionAddress).transferToken();
    }
}
