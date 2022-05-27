//SPDX-License-Identifier: Unlicense
//THIS CONTRACT IS FOR TESTING PURPOSES AND GOOD VIBES ONLY
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MockNFTBSC is ERC721Enumerable, Ownable {
    string[] mockTokenURI = [
        "https://tofu.bft.finance/api/bft/",
        "ipfs://QmXm2rdQbxV6hNRqESmiBTj161hRZnbBqc1mcHM7hWo66X/",
        "https://api.kryptomon.co/json/kryptomon/meta/",
        "https://api.hatswapcity.com/v1/"
    ];

    constructor(address[] memory _owners, uint256 _amount) ERC721("Mock NFT", "mNFT") {
        //mint mock to owner
        for (uint256 i = 0; i < _amount; i++) {
            for (uint256 j = 0; j < _owners.length; j++) {
                _safeMint(_owners[j], j * _amount + i);
            }
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
                    Strings.toString(tokenId+10)
                )
            );
    }
}
