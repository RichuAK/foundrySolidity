// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

// import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {Script, console} from "forge-std/Script.sol";

contract ElevenScript is Script {
    function run() external view {
        address lessonEleven = 0x93c7A945af9c453a8c932bf47683B5eB8C2F8792;
        uint256 i = 0;
        bytes32 slot;
        address helperContractAddress;
        for (i = 0; i < 30; i++) {
            slot = vm.load(address(lessonEleven), bytes32(uint256(i)));
            helperContractAddress = address(uint160(uint256(slot)));
            console.log(
                "Typecasted Address: at",
                i,
                "    ",
                helperContractAddress
            );
        }
        // bytes32 slot0 = vm.load(address(lessonEleven), bytes32(uint256(0)));
        // address helperContractAddress = address(uint160(uint256(slot0)));
        // console.log("Slot 0: ", string(bytes(slot0)));
        // console.log("Typecasted Address: ", helperContractAddress);
    }
}
