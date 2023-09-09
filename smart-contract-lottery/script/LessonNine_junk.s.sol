// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract LessonNine {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external {}
}

contract FoundryCourseNFT {
    function transferFrom(address from, address to, uint256 tokenId) external {}
}

contract LessonNineSolution {
    LessonNine lessonNine =
        LessonNine(0x33e1fD270599188BB1489a169dF1f0be08b83509);

    address foundryCourseNFTAddress =
        0x76B50696B8EFFCA6Ee6Da7F6471110F334536321;
    address public owner;
    uint256 public recievedToken;

    constructor() {
        owner = msg.sender;
    }

    function solveC() public {
        uint256 correctAnswer = uint256(
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.prevrandao,
                    block.timestamp
                )
            )
        ) % 100000;

        lessonNine.solveChallenge(correctAnswer, "reead");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        recievedToken = tokenId;
        return this.onERC721Received.selector;
    }

    function transferToken() public {
        FoundryCourseNFT(foundryCourseNFTAddress).transferFrom(
            address(this),
            owner,
            recievedToken
        );
    }

    // lessonNine.transferFrom(address(this), address owner, tokenId);
}
