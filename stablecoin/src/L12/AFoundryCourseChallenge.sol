// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AFoundryCourseChallenge {
    constructor(address FoundryCourseNftNft) {}
    function description() external view virtual returns (string memory) {}

    function extraDescription(address user) external view virtual returns (string memory) {}

    function specialImage() external view virtual returns (string memory) {}

    function attribute() external view virtual returns (string memory) {}

    function _updateAndRewardSolver(string memory twitterHandleOfSolver) internal {}

    /* Each contract must have a "solveChallenge" function, however, the signature
     * maybe be different in all cases because of different input parameters.
     * Because of this, we are not going to define the function here.
     *
     * This function should call back to the FoundryCourseNft contract
     * to mint the NFT.
     */
    // function solveChallenge() external;
}
