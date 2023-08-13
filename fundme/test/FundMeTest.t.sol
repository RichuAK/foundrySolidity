// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// console is a module inside Test, for console logging values for debugging
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // declaring here for global scope in the contract
    FundMe fundMe;

    // makes an address and assigns to USER.
    // foundry stuff. Adress is created at complie time, so can't be constant (?)
    address USER = makeAddr("user");

    // this setUp method runs first everytime you run test
    function setUp() external {
        // passing in the Sepolia Address for PriceConverter
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundme = new DeployFundMe();
        fundMe = deployFundme.run();
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
        // assertEq(fundMe.i_owner(), address(this));
        // reverting back to the old version after DeployFundMe becomes the FundMe deployer
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testVersionofAggregator() public {
        uint256 version = fundMe.getVersion();
        console.log("Testing the version of AggregatorV3Interface");
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // just texting expectRevert
        vm.expectRevert();
        uint256 a = 5;
        if (a == 5) {
            revert();
        }
    }
}
