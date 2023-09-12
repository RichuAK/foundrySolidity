// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {Script} from "forge-std/Script.sol";
import {DeployNeapolitanNFT} from "./DeployNeapolitanNFT.s.sol";

contract Interactions is Script {
    NeapolitanNFT neapolitanNFT;

    function run() external {
        DeployNeapolitanNFT deployNFT = new DeployNeapolitanNFT();
        vm.broadcast();
        neapolitanNFT = deployNFT.run();
        mintNFTFromDeployed();
    }

    function mintNFTFromDeployed() internal {
        vm.broadcast();
        neapolitanNFT.mintNft("Some stupid hash of a junk picture");
    }
}
