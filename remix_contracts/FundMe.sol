// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// importing from the library
import {PriceConverter} from "./PriceConverter.sol";

//        ^ always go for named imports

// custom error, saves gas. New Solidity feature
error Failure();

contract FundMe {
    // attach the library for the datatype. This makes all the methods in the library implicit to the datatype
    using PriceConverter for uint256;

    // to be set as the owner in constructor
    // declared as immutable since it won't be changed
    // different from constant since the value is set in a function, rather than outside everything
    address public immutable i_owner;

    // constructor, executed with the contract creation transaction
    constructor() {
        i_owner = msg.sender;
    }

    // modifier that sets the modifying logic for repeated admin checks
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Trespassing! You're not the owner");
        _;
    }

    // 10 dollars, with 18 zeros for the Wei conversion math to work in later arithmetic
    // stored as a constant to save gas. Since it won't be changed anywhere
    uint256 public constant MINIMUM_USD = 10e18;

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
            msg.value.convertEthToUSD() >= MINIMUM_USD,
            "Less than 10 dollars, you're too cheap!"
        );
        // update the list of funders who've sent money
        funders.push(msg.sender);
        // update their donation records.
        addressToAmountFunded[msg.sender] += msg.value;
    }

    // withdrawing all the funds in the contract and re-initializing the records
    function withdraw() public onlyOwner {
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
        // this is using the custom error declared way up above, instead of the old require
        if (!callSuccess) {
            revert Failure();
        }
        // require(callSuccess, "Call failed!");
    }

    // two special functions to handle stray transactions hitting the contract
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
