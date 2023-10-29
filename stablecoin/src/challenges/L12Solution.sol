// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract LessonTwelveSolution {
    uint128 private constant NUMBER = 99;
    address private constant OWNER = 0xcF78399B272E71F23F00b453005e9ba0EFa9FcDc;

    function getOwner() public pure returns (address) {
        return OWNER;
    }

    function getNumberr() public pure returns (uint128) {
        return NUMBER;
    }
}
