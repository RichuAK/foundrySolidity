// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {FlipNFT} from "../src/FlipNFT.sol";
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

contract MintFlipNFT is Script {
    function run() external {
        address flipNFTAddress = DevOpsTools.get_most_recent_deployment(
            "FlipNFT",
            block.chainid
        );
        mintFlipNFT(flipNFTAddress);
    }

    function mintFlipNFT(address flipNFTAddress) internal {
        vm.broadcast();
        FlipNFT(flipNFTAddress).mint();
    }
}

contract FlipFlipNFT is Script {
    // uint256 public s_tokenId;

    // constructor(uint256 tokenId) {
    //     s_tokenId = tokenId;
    // }
    // DOES THIS WORK?? IS THERE A WAY TO MAKE THIS WORK?

    uint256 private constant STATIC_TOKEN_ID = 0;

    function run() external {
        address flipNFTAddress = DevOpsTools.get_most_recent_deployment(
            "FlipNFT",
            block.chainid
        );
        flipFlipNFT(flipNFTAddress);
    }

    function flipFlipNFT(address flipNFTAddress) internal {
        vm.broadcast();
        FlipNFT(flipNFTAddress).flipMood(STATIC_TOKEN_ID);
    }
}
