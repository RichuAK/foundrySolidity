// Lesson 3
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//imports only the specified contract(s) from the imported file
//much better control over what's being impored, instead of a blind import of the whole file.
//called 'named import'
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

    //calling a function of another contract from this contract
    //since the whole other contract was imported, it has the ABI already
    function sfStore(uint256 _index, uint256 _numberToStore) public {
        //initiating simpleStage like this is a bit longform
        SimpleStorage simpleStorage = listOfSimpleStorage[_index];
        simpleStorage.store(_numberToStore);
    }

    function sfRead(uint256 _index) public view returns (uint256) {
        //the short form of directly calling the method since we know the list contains SimpleStorage datatypes
        return listOfSimpleStorage[_index].retrieve();
    }
}
