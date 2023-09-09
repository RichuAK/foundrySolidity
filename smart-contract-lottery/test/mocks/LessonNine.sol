// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract LessonNine {
    // bool public challengeSolved;

    constructor() {
        // challengeSolved = false;
    }

    function solveChallenge(uint256 randomGuess) external view returns (bool) {
        // Do we have a 1 in 100,000 chance of getting it right?
        // ...or can we cheat?
        uint256 correctAnswer = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 100000;

        if (randomGuess == correctAnswer) {
            return true;
        } else {
            return false;
        }
    }
}
