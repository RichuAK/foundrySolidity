// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {NeapolitanNFT} from "../src/NeapolitanNFT.sol";
import {DeployNeapolitanNFT} from "../script/DeployNeapolitanNFT.s.sol";
import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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
        neapolitanNFT.mintNft("Hello"); //not a proper URI, but works for this purpose(?)
        // Assert
        assert(USER == neapolitanNFT.ownerOf(0)); // since this will be the first token that's minted
    }

    function testTokenURI() public {
        // Arrange
        vm.prank(USER);
        neapolitanNFT.mintNft("Hello");
        // Act
        string memory returnedTokenURI = neapolitanNFT.tokenURI(0);
        // Assert
        assertEq(
            keccak256(abi.encodePacked("Hello")),
            keccak256(abi.encodePacked(returnedTokenURI))
        );
    }

    function testTokenCounter() public {
        // Arrange
        uint256 i;
        uint256 NftToMint = 100;
        vm.startPrank(USER);
        for (i = 1; i <= NftToMint; i++) {
            string memory junkURI = Strings.toString(i); // from the OpenZeppelin Strings library so the strings conversion can be done smoothly
            neapolitanNFT.mintNft(string.concat("Hello: ", junkURI)); // string.concat is a built in function from 0.8.12
        }
        vm.stopPrank();
        // Act
        uint256 tokenCounter = neapolitanNFT.getTokenCounter();
        // Assert
        assert(tokenCounter == NftToMint);
    }
}
