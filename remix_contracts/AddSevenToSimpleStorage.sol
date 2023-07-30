// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//imports only the specified contract(s) from the imported file
//much better control over what's being impored, instead of a blind import of the whole file.
import {SimpleStorage} from "./SimpleStorage.sol";

contract AddSeven is SimpleStorage {
    //overrides the store function from the parent contract. Everything else stays the same
    function store(uint256 _number) public override {
        myFavoriteNumber = _number + 7;
    }
}
