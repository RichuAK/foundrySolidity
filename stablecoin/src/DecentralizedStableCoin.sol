// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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
// view & pure functions

pragma solidity 0.8.21;

/**
 * @notice Only importing ERC20Burnable instead of Both Burnable and ERC20 as in the course
 * @notice Since Burnable is an extension that inherits from ERC20. Will see if works
 * @notice Doesn't work, you need to import ERC20 for the constructor
 */
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/Extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Richu A Kuttikattu (not really, but okay)
 * @notice Meant to be governed by DSCEngine. This is just an ERC20 implementation of the stablecoin system
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__MustBeLessThanBalance();
    error DecentralizedStableCoin__CantSendToZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    /**
     *
     * @param _amount amount to be burned
     * @dev does a couple of checks and reverts or executes the original burn
     */
    function burn(uint256 _amount) public override onlyOwner {
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balanceOf(msg.sender) < _amount) {
            revert DecentralizedStableCoin__MustBeLessThanBalance();
        }
        // executes the burn function of the super class.
        super.burn(_amount);
        // the checks look a bit redundant to me, they're being performed in the original definition as well
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (_to == address(0)) {
            revert DecentralizedStableCoin__CantSendToZeroAddress();
        }
        _mint(_to, _amount);
        return true;
    }
}
