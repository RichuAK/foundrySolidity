// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// console is a module inside Test, for console logging values for debugging
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    // declaring here for global scope in the contract
    FundMe fundMe;

    // this setUp method runs first everytime you run test
    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumDollarisFive() public {
        console.log("Asserting MinUSD..");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testSenderisOwner() public {
        console.log("Checking Owner..");
        // FunMe contract owner is the test contract in this scenario
        // and msg.sender is you. So assert is gonna fail
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        // assert succeeds when address(this) is checked against owner
        assertEq(fundMe.i_owner(), address(this));
    }
}