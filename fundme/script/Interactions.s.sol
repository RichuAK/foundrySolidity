// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";
import {LessonSevenSolution} from "../src/LessonSevenSolution.sol";

// function interactWithPreviouslyDeployedContracts() public {
//     address contractAddress = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
//     MyContract myContract = MyContract(contractAddress);
//     myContract.doSomething();
// }

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded with %s money", SEND_VALUE);
    }

    function run() external {
        address fundMeAddress = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(fundMeAddress);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Attempted Withdraw");
    }

    function run() external {
        address fundMeAddress = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(fundMeAddress);
    }
}

contract FindSolutionForLessonSeven is Script {
    function findSolutionForLessonSeven(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        console.log("Attempting to find Solution for Lesson Seven");
        LessonSevenSolution(mostRecentlyDeployed).solveLessonSeven();
        vm.stopBroadcast();
    }

    // Hard coding the deployed address to skip ffi setting. Not recommended is you want to rely on DevOps
    function run() external {
        address lessonSevenSolutionAddresses = DevOpsTools
            .get_most_recent_deployment("LessonSevenSolution", block.chainid);
        findSolutionForLessonSeven(lessonSevenSolutionAddresses);
    }

    // function run() external {
    //     // address lessonSevenSolutionAddresses = DevOpsTools
    //     //     .get_most_recent_deployment("LessonSevenSolution", block.chainid);
    //     findSolutionForLessonSeven(0x75ABE744b11FC62e2FBF66e51f858783e0Eb822C);
    // }
}
