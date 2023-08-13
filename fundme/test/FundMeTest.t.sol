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
    // contant to set the balance of USER in the beginning. Declared to avoid magic numbers
    uint256 constant STARTING_BALANCE = 10e18; // 10 ether, basically
    // a transaction value. Ether gets converted to wei so no decimals in the end
    uint256 constant SEND_VALUE = 0.1 ether;

    // this setUp method runs first everytime you run test
    function setUp() external {
        // passing in the Sepolia Address for PriceConverter
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundme = new DeployFundMe();
        fundMe = deployFundme.run();
        // cheatcode to set the balance of the madeup address
        vm.deal(USER, STARTING_BALANCE);
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
        // testing expectRevert
        vm.expectRevert();
        // this should revert since there's no funds being sent.
        // And if it reverts, the test succeeds
        fundMe.fund();

        // Like this code snippet:
        // uint256 a = 5;
        // if (a == 5) {
        //     revert();
        // }
    }

    // function to check whether the database is correctly updated
    function testFundMethodUpdatesMapping() public {
        // another cheatcode in the test suite
        // pranks the next transaction, so that it appears as if it's sent by USER
        vm.prank(USER);
        // calls the function as if USER is msg.sender
        fundMe.fund{value: SEND_VALUE}();
        // default getter fucntio for addressToAmountFunded
        // declare it as private and write explicit getter functions to save gas
        uint256 sent_value = fundMe.addressToAmountFunded(USER);
        assertEq(sent_value, SEND_VALUE);
    }
}
