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
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 length,
        RaffleState raffleState
    );

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
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // VRFCoordinator Variables
    // Clustered by me, not standard
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane; //keyHash, better named as gasLane
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /**Event Declarations */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /**
     * @param entranceFee to set the i_entranceFee at deployment
     * @param interval set to i_interval at deployment
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

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

    // Refactoring into Chainlink Automation

    /**
     * @dev contract functions docs: https://docs.chain.link/chainlink-automation/flexible-upkeeps
     * @dev The function that the ChainLink Automation nodes all to see if it's time to perform an upkeep.
     * Conditions to be true for the function to return true:
     * 1. Time interval has passed between raffle runs.
     * 2. RaffleState is OPEN
     * 3. The contract has ETH (sent by players)
     * 4. (Implicit) The subscription is funded with LINK  - it is a service, after all.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */ // naming (initializing) the return variable here
        )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleIsOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed &&
            raffleIsOpen &&
            hasBalance &&
            hasPlayers);
        // no need to 'return upkeepNeeded' since it's initialized in the function declaration
        // but, we'll be a bit explicit:
        return (upkeepNeeded, "0x00"); // "0x00" is the blank bytes object, for the second variable
    }

    // Wait and get a random number from the oracle, and then get pick the winner based on that VRF
    // Refactored with ChainLink automation
    function performUpKeep(bytes calldata /* checkData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                s_raffleState
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // redundant, since there's a similar event in VRFCoordinatorMock already.
        // but doing for testing purposes
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        // reinitialisations of states for the next round
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = winner;
        emit PickedWinner(winner);
        // end of reinitializations of states
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__PriceDistributionFailed();
        }
    }

    // Getter Functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getPlayersSize() public view returns (uint256) {
        return s_players.length;
    }

    function getPlayerAtIndex(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
