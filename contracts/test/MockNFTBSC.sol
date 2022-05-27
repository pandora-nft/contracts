//SPDX-License-Identifier: Unlicense
//THIS CONTRACT IS FOR TESTING PURPOSES AND GOOD VIBES ONLY
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
contract MockNFTBSC is ERC721Enumerable, Ownable {
    string[] mockTokenURI = [
        "https://tofu.bft.finance/api/bft/",
        "ipfs://QmXm2rdQbxV6hNRqESmiBTj161hRZnbBqc1mcHM7hWo66X/",
        "https://api.kryptomon.co/json/kryptomon/meta/",
        "https://api.hatswapcity.com/v1/"
    ];
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    constructor() ERC721("Mock NFT", "mNFT") {}

    function mockMint(uint256 _amount) public {
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function mockMintTo(address _to, uint256 _amount) public {
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    mockTokenURI[tokenId % mockTokenURI.length],
                    Strings.toString((tokenId % 50) + 10)
                )
            );
    }
}
