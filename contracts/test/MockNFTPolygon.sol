//SPDX-License-Identifier: Unlicense
//THIS CONTRACT IS FOR TESTING PURPOSES AND GOOD VIBES ONLY
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract MockNFTPolygon is ERC721Enumerable, Ownable {
    string[] mockTokenURI = [
        "ipfs://QmaAY3aQe8a8tDt24RaQtQX7pMGRQoarGF6pVYn5cpLyLX/",
        "ipfs://QmVoe89fH1xCAC51Q5oRb2VLmVg8VncYU37rv7TLxCuTQD/",
        "https://api.sunflower-land.com/nfts/farm/"
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
