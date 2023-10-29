// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract LoadSlot is Script {
    address contractAddress = 0xaFa4150818b7843345A5E54E430Bd0cAE31B5c0C;
    uint256 slotNumber = 0;
    bytes32 valueAtSlot;

    function run() external {
        valueAtSlot = loadAtSlot();
        console.logString("Value:");
        console.logBytes32(valueAtSlot);
        console.logString("Value as Int:");
        console.logInt(int256(uint256(valueAtSlot)));
        int256 numberAtSlot = int256(uint256(valueAtSlot));
        int256 numberToFind = 1337 - (numberAtSlot + int256(10));
        console.logString("Value to Pass/Find:");
        console.logInt(numberToFind);
        // int256 number = -572038313094850821099624258919152072749626291038;
    }

    function loadAtSlot() public view returns (bytes32) {
        return vm.load(contractAddress, bytes32(slotNumber));
    }
}
