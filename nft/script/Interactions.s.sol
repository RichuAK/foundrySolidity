// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {Script} from "forge-std/Script.sol";
import {DeployNeapolitanNFT} from "./DeployNeapolitanNFT.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintNapoliNFT is Script {
    function run() external {
        // DeployNeapolitanNFT deployNFT = new DeployNeapolitanNFT();
        // vm.startBroadcast();
        // neapolitanNFT = deployNFT.run();
        // vm.stopBroadcast();
        address neapolitanNFTAddress = DevOpsTools.get_most_recent_deployment(
            "NeapolitanNFT",
            block.chainid
        );
        mintNFTFromDeployed(neapolitanNFTAddress);
    }

    function mintNFTFromDeployed(address NFTAddress) internal {
        vm.startBroadcast();
        NeapolitanNFT(NFTAddress).mintNft("Some stupid hash of a junk picture");
        vm.stopBroadcast();
    }
}
