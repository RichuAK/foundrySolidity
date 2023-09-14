// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract FlipNFT is ERC721 {
    error FlipNFT__CantFlipIfNotOwnerOrApproved();
    error FlipNFT__TokenDoesntExist();

    uint256 private s_tokenCounter;
    string private s_happySvgUri;
    string private s_sadSvgUri;
    mapping(uint256 => Mood) private s_tokenIdToMood;

    enum Mood {
        HAPPY,
        SAD
    }

    event TokenMinted(address indexed, uint256 indexed);

    constructor(
        string memory sadSvgUri,
        string memory happySvgUri
    ) ERC721("Flip NFT", "FNT") {
        s_tokenCounter = 0;
        s_happySvgUri = happySvgUri;
        s_sadSvgUri = sadSvgUri;
    }

    /**
     * @dev a mint function which anyone can call
     * Mints a token by calling _safeMint() in the base ERC721 implementation
     */
    function mint() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        emit TokenMinted(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    /**
     *
     * @param tokenId the tokenId of the NFT to be flipped
     * @dev toggles the mood of the nft. Flips it to the other enum state
     */
    function flipMood(uint256 tokenId) public {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert FlipNFT__CantFlipIfNotOwnerOrApproved();
        }
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert FlipNFT__TokenDoesntExist();
        }
        string memory imageUri;
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            imageUri = s_happySvgUri;
        } else {
            imageUri = s_sadSvgUri;
        }
        string memory tokenUri = string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"An NFT that is dynamic, with moods that can be flipped by the NFT owner. 100% on Chain", ',
                            '"attributes": [{"trait_type": "flipping flop", "value": 100}], "image":"',
                            imageUri,
                            '"}'
                        )
                    )
                )
            )
        );
        return tokenUri;
    }

    function getHappySvgUri() public view returns (string memory) {
        return s_happySvgUri;
    }

    function getSadSvgUri() public view returns (string memory) {
        return s_sadSvgUri;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
