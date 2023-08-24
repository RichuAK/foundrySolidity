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

/**
 * @title Sample Raffle Contract
 * @author Richu A Kuttikattu, via Patrick Collins
 * @notice A contract for creating a sample Raffle, for educational purposes
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    // custom error as a (slightly) gas efficient alternative to require
    // naming convention with the contract name prefix, for easy debugging out there
    error Raffle__NotEnoughEthSent();

    /**
     * @dev all state variables. i_ are immutables, s_ are storage variables
     * @dev declared private and then written an explicit getter function down below to save gas
     */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /**
     * @param entranceFee to set the i_entranceFee at deployment
     */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
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
        // pushing the address into the dynamic array
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {}

    // Getter Functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
