// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    GovernanceToken govToken;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    address public USER = makeAddr("user");

    // All the arrays passed into the 'propose' function in MyGovernor.sol (via Governor.sol)
    address[] proposers;
    address[] executors;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;
    uint256 public constant VOTING_DELAY = 1; //From Governor wizard's default settings at the time of wizardry
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts. Week long delay, again from the governor contract

    function setUp() public {
        // creates the contract and mints INITIAL_SUPPLY to USER
        govToken = new GovernanceToken(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        // delegates the votes to self, so you can vote. Can delegate to someone else as well, of course
        govToken.delegate(USER);
        timelock = new TimeLock (MIN_DELAY, proposers, executors);
        governor = new MyGovernor (govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE(); //v5 updated lingo, I think
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    // Just a sanity check
    function testBoxCantUpdateWithoutGovernance() public {
        vm.expectRevert();
        box.store(2423);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = "Store 777 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        targets.push(address(box));
        values.push(0);
        calldatas.push(encodedFunctionCall);
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        console.log("Proposal State:", uint256(governor.state(proposalId)));
        // console.log("Snapshot: ", uint256(governor.proposalSnapshot(proposalId)));
        // console.log("DeadLine: ", uint256(governor.proposalDeadline(proposalId)));

        // vm.warp(block.timestamp + VOTING_DELAY + 1);
        // vm.roll(block.number + VOTING_DELAY + 1);

        // This works, but the above warp and roll amounts doesn't.
        // TODO: Dig deeper into why this is the case
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "I like the 777 burger from Las Vegas as the epitome of hedonism";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;

        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
    }
}
