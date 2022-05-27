//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract SuperRare is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    string[] mockTokenURI = [
        "ipfs://QmTDcCdt3yb6mZitzWBmQr65AW6Wska295Dg9nbEYpSUDR/",
        "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
        "ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/",
        "ipfs://QmWiQE65tmpYzcokCheQmng2DCM33DEhjXcPB6PanwpAZo/"
    ];

    Counters.Counter public tokenIdCounter;

    constructor() ERC721("Mock NFT", "mNFT") {
        //mint mock to owner
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

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
                    Strings.toString(((tokenId * 12) % 512) + 1)
                )
            );
    }
}
