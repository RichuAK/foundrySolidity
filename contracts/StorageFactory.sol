// Lesson 3
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//imports only the specified contract(s) from the imported file
//much better control over what's being impored, instead of a blind import of the whole file.
import {SimpleStorage, NotUsedContract} from "./SimpleStorage.sol";

contract StorageFactory {
    //uint256 public favoriteNumber
    //datatype visibility variableName
    //similarly:
    // SimpleStorage public simpleStorage;

    // list of contracts
    SimpleStorage[] public listOfSimpleStorage;

    function createSimpleStorageContract() public {
        // deploys a new SimpleStorage contract and assigns to simpleStorage variable
        // simpleStorage = new SimpleStorage();
        // declaring and assigning the variable in one go:
        SimpleStorage simpleStorage = new SimpleStorage();
        listOfSimpleStorage.push(simpleStorage);
    }
}
