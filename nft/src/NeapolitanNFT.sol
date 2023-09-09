// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NeapolitanNFT is ERC721 {
    uint256 private s_tokenCounter;

    constructor() ERC721("Neapolitan Novels", "NNT") {
        s_tokenCounter = 0;
    }
}
