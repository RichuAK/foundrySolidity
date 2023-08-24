// Recommnended Contract Layout by the Big Guys:

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Sample Raffle Contract
 * @author Richu A Kuttikattu, via Patrick Collins
 * @notice A contract for creating a sample Raffle, for educational purposes
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2 {
    // custom error as a (slightly) gas efficient alternative to require
    // naming convention with the contract name prefix, for easy debugging out there
    error Raffle__NotEnoughEthSent();
    error Raffle__PriceDistributionFailed();
    error Raffle__NotOpen();

    /**Type Declarations */
    // enum special derived datatype, as a set of flags of sorts
    // https://docs.soliditylang.org/en/v0.8.21/types.html#enums
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * @dev all state variables. i_ are immutables, s_ are storage variables
     * @dev declared private and then written an explicit getter function down below to save gas
     * @dev i_interval is the time interval between two winner picks
     * @dev lastPick is the time at which the last lottery was picked
     */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastPickTime;
    RaffleState private s_raffleState;

    // VRFCoordinator Variables
    // Clustered by me, not standard
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane; //keyHash, better named as gasLane
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /**
     * @param entranceFee to set the i_entranceFee at deployment
     * @param interval set to i_interval at deployment
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastPickTime = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_raffleState = RaffleState.OPEN;
    }

    /** Events */
    event EnteredRaffle(address indexed player);

    /**
     * @dev payable function to pay and buy the ticket, so users can enter the competition
     * @dev external is more efficient than public, and no one's gonna call the fuction from within the contract.
     */
    function enterRaffle() external payable {
        // require replaced by custom error
        // require(msg.value>=i_entranceFee, "Not Enough Fee to Enter the Raffle!");
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        // pushing the address into the dynamic array
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // Needs to do 2 things (or 3?) as two different transactions
    // Wait and get a random number from the oracle, and then get pick the winner based on that VRF
    function pickWinner() external {
        if ((block.timestamp - s_lastPickTime) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__PriceDistributionFailed();
        }
        s_raffleState = RaffleState.OPEN;
    }

    // Getter Functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
