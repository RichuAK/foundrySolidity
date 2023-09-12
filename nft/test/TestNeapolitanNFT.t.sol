// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {DeployNeapolitanNFT} from "../script/DeployNeapolitanNFT.s.sol";
import {Test} from "forge-std/Test.sol";

// import {Script} from "forge-std/Script.sol";

contract TestNeapolitanNFT is Test {
    NeapolitanNFT neapolitanNFT;

    address USER = makeAddr("USER");

    function setUp() external {
        DeployNeapolitanNFT deployNeapolitan = new DeployNeapolitanNFT();
        neapolitanNFT = deployNeapolitan.run();
    }

    function testNeapolitanName() public view {
        // Arrange / Act
        string memory NFTName = neapolitanNFT.name();
        string memory supposedName = "Neapolitan Novels";
        // Assert
        // strings are not primitive types, so we hash them and then compare them as bytes32 objects
        assert(
            keccak256(abi.encodePacked(NFTName)) ==
                keccak256(abi.encodePacked(supposedName))
        );
    }

    function testMinting() public {
        // Arrange/Act
        vm.prank(USER);
        neapolitanNFT.mintNft("Hello");
        // Assert
        assert(USER == neapolitanNFT.ownerOf(0)); // since this will be the first token that's minted
    }
}
