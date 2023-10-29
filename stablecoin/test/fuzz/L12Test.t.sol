// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";

import {LessonTwelveHelper} from "../../src/L12/12-LessonHelper.sol";

contract L12Test is Test {
    LessonTwelveHelper hell;
    // uint128 hellInput;

    function setUp() external {
        hell = new LessonTwelveHelper();
        // targetContract(address(hell));
    }

    function testUnitHellCalculation() public view {
        uint128 hellInput = 99;
        uint256 answer = hell.hellFunc(hellInput);
        assert(answer >= 0);
    }

    function testHellCalculation(uint128 hellInput) public view {
        uint256 answer = hell.hellFunc(hellInput);
        assert(answer >= 0);
    }
}
