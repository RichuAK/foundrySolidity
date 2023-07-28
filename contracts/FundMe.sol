// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// importing from the library
import {PriceConverter} from "./PriceConverter.sol";

//        ^ always go for named imports

contract FundMe {
    // attach the library for the datatype. This makes all the methods in the library implicit to the datatype
    using PriceConverter for uint256;

    // 10 dollars, with 18 zeros for the Wei conversion math to work in later arithmetic
    uint256 public minimumUsd = 10e18;

    // list of addresses that have sent funds
    address[] public funders;

    // mapping to keep track of amounts sent by each funder
    // 'funder' and 'amountFunded' here are just syntactic sugar, to make things more readable and understandable
    mapping(address funder => uint256 amountFunded)
        public addressToAmountFunded;

    // method to recieve the funds and update the records.
    function fund() public payable {
        // check whether there's more than a minimum money being donated. Revert otherwise.
        // notice the .method below: 'msg.value' is a uint256, so you access 'convertEthtoUSD as an extended method
        require(
            msg.value.convertEthToUSD() >= minimumUsd,
            "Less than 10 dollars, you're too cheap!"
        );
        // update the list of funders who've sent money
        funders.push(msg.sender);
        // update their donation records.
        addressToAmountFunded[msg.sender] += msg.value;
    }

    // withdrawing all the funds in the contract and re-initializing the records
    function withdraw() public {
        // looping through the funders array
        for (uint256 index = 0; index < funders.length; index++) {
            // getting the key (address)
            address funder = funders[index];
            // blindly updating the value to zero
            addressToAmountFunded[funder] = 0;
        }

        // re-initializing funders as an address array with just the first element.
        // another way to use the new keyword, in addition to contract deployment.
        funders = new address[](0);

        // ways of transferring money
        // refer to Solidity-by-Example for in-depth walk throughs

        // via 'transfer'
        // typecast the reciever address into a payable address, transfer the whole balance.
        // transaction reverts if the method fails.
        /* 
        payable(msg.sender).transfer(address(this).balance); 
        */

        // via 'send'
        // transaction won't revert if the method fails. But returns a bool
        // check the bool and do accordingly!
        /*
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "sending failed!");
        */

        // via 'call'
        // a low level method, extremely powerful and useful, if you know what you're doing!!
        // can call any method in any contract, anywhere.
        // returns a bool and bytes array, we're only interested in the bool now
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }
}
