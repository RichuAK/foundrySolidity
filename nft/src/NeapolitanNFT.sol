// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NeapolitanNFT is ERC721 {
    error NeapolitanNFT__TokenUriNotFound();
    uint256 private s_tokenCounter;
    mapping(uint256 tokenId => string tokenUri) private s_tokenIdToUri;

    constructor() ERC721("Neapolitan Novels", "NNT") {
        s_tokenCounter = 0;
    }

    /**
     * @dev mint an nft by passing the tokenUri yourself
     * @param tokenUri a string which ideally should be an IPFS hash of a JSON object
     */
    function mintNft(string memory tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    /**
     * @dev overriding the OpenZeppeling implementation since there is no baseURI to append to
     * @param tokenId the tokenId of the NFT
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NeapolitanNFT__TokenUriNotFound();
        }
        return s_tokenIdToUri[tokenId];
    }
}
