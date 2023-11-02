// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract OtherContract {
    uint256 public variable1 = 0;
    uint256 public variable2 = 0;

    function getOwner() external pure returns (address) {
        return 0xcF78399B272E71F23F00b453005e9ba0EFa9FcDc;
    }

    function doSomething() public {
        variable1 = 123;
        variable2 = 1;
    }

    // bytes4 selector = 0x2f576f20
    function doNothing() public {}
}
