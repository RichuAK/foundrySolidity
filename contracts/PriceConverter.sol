// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// assuming npm installation is done locally, if not done on remix. remix and npm gets it from GitHub as well.
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // function to get the realtime price of Eth in USD using Chainlink's price aggregator contract.
    function getEthPrice() public view returns (uint256) {
        AggregatorV3Interface EthPrice = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

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
}
