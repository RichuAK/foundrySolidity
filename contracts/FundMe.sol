// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// assuming npm installation is done locally instead of remix. npm gets it from GitHub as well.
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//        ^ always go for named imports

contract FundMe {
    // 10 dollars, with 18 zeros for the Wei conversion math to work in later arithmetic
    uint256 public minimumUsd = 10e18;

    AggregatorV3Interface EthPrice =
        AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

    // list of addresses that have sent funds
    address[] public funders;

    // mapping to keep track of amounts sent by each funder
    // 'funder' and 'amountFunded' here are just syntactic sugar, to make things more readable and understandable
    mapping(address funder => uint256 amountFunded)
        public addressToAmountFunded;

    // function to get the realtime price of Eth in USD using Chainlink's price aggregator contract.
    function getEthPrice() public view returns (uint256) {
        // ignoring all the other variables by just putting empty commas in there.
        (
            ,
            /* uint80 roundID */ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = EthPrice.latestRoundData();

        // this 'answer' has 8 decimal places (there's another function in the interface to check it)
        // So, 2000.00000000 USD gets returned as 200000000000
        // but msg.value is in wei, which has 18 decimals (18 digits, since there are no decimals in Solidity)
        // Also, msg.value is a uint, while 'answer' is int.
        // So multiply answer with the remaining decimals and typecast it before returning.
        return uint256(answer * 1e10);
    }

    function convertEthToUSD(uint256 _ethAmount) public view returns (uint256) {
        // get the price of Eth in Wei from the above defined function
        uint256 ethPrice = getEthPrice();
        // both ethPrice and _ethAmount will be in Wei, each with 18 digits.
        // The product of these two numbers is going to be 36 digits, which we have to bring back down to 18 by the division
        uint256 EthtoUSD = (ethPrice * _ethAmount) / 1e18;
        // ^ rule of thumb: always multiply before division since decimals don't exist in Solidity
        return EthtoUSD;
    }

    // method to recieve the funds and update the records.
    function fund() public payable {
        // check whether there's more than a minimum money being donated. Revert otherwise.
        require(
            convertEthToUSD(msg.value) >= minimumUsd,
            "Less than 10 dollars, you're too cheap!"
        );
        // update the list of funders who've sent money
        funders.push(msg.sender);
        // update their donation records.
        addressToAmountFunded[msg.sender] += msg.value;
    }
}
