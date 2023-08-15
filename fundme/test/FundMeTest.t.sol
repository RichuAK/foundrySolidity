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

    // test to see the array of funders is getting updated
    function testFunderGetsAddedToFundersArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        // each test is run independently, after discarding everything prior and then running setup()
        // that's why we have to invoke fund() again and USER is at the 0th index
        // everything's sorta at the genesis state when each of these tests are run
        address funder = fundMe.funders(0);
        assertEq(funder, USER);
    }

    // function to see if only the Owner can withdraw
    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        // this ^ could have been the modifier, but explicitly written to show vm.prank multiple calls

        vm.expectRevert();
        // prank needs to be called again since prank only works for the very text transaction
        // it's not set for the entire method scope, just the next transaction
        vm.prank(USER);
        fundMe.withdraw();
    }

    // modifier to clean up the code
    // things that tend to get repeated again and again
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // my version of the test as an exercise of thinking through
    function testWithdrawWithASingleFunder_myVersion() public funded {
        // Arrange
        // so we can track the owner's balance.
        // tip: this contract is not the owner, and deployFundMe from setup() is not available here either
        // also, again, default getter is not recommended; set variables private and write explicit getters
        uint256 oldBalance = address(fundMe.i_owner()).balance;
        // Act
        console.log("Testing Successful Withdraw");
        vm.prank(fundMe.i_owner());
        fundMe.withdraw();
        // Assert
        assertEq((address(fundMe.i_owner()).balance - oldBalance), SEND_VALUE);
    }

    // Patrick's version, after having watched the video
    function testWithdrawWithASingleFunder_patrick() public funded {
        // Arrange
        // Too lazy to write a getter function in fundMe.
        // And it'll break my version; so keeping it as is
        uint256 startingOwnerBalance = address(fundMe.i_owner()).balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        console.log("Testing Successful Withdraw via GOAT");
        // vm.txGasPrice simulates gas costs in Anvil. It's all zero cost otherwise.
        // GAS_PRICE is a constant to evade magic numbers, but not declared in this since it's commented
        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        vm.prank(fundMe.i_owner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // tx.gasprice is a solidity native:
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // Assert
        uint256 endingOwnerBalance = address(fundMe.i_owner()).balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    // my version of the test, before watching the GOAT
    function testWithdrawFromMultipleFunders_myVersion() public funded {
        // Arrange
        address USER2 = makeAddr("user2");
        vm.deal(USER2, STARTING_BALANCE);
        vm.prank(USER2);
        fundMe.fund{value: SEND_VALUE}();
        uint256 startingOwnerBalance = address(fundMe.i_owner()).balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        console.log("Testing Successful Withdraw after multiple funders");
        vm.prank(fundMe.i_owner());
        fundMe.withdraw();
        // Assert
        uint256 endingOwnerBalance = address(fundMe.i_owner()).balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(endingOwnerBalance - startingOwnerBalance, 2 * SEND_VALUE);
    }

    // GOAT version
    function testWithdrawFromMultipleFunders_Patrick() public funded {
        // Arrange

        // it's uint160 is because of Solidity update.
        // typecasting address and uint256 is deprecated, it's 160 now
        uint160 numberofFunders = 10;
        // no reason for 160 here, just making things symmetrical
        uint160 startingFunderIndex = 1;
        // loop to bring them all alive (make the accounts and fund)
        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            // instead of makeAddr and vm.deal, we use a different paradigm
            // hoax is part of foundry package, so don't need to use vm
            // it makes the account and funds the too.
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = address(fundMe.i_owner()).balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act

        // everything between startPrank and stopPrank will be as if the transactions are sent by the pranker
        vm.startPrank(fundMe.i_owner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert

        // instead of assertEq, we use assert
        assert(address(fundMe).balance == 0);
        assert(
            address(fundMe.i_owner()).balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }
}
