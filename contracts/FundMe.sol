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
}
