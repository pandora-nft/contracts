//SPDX-License-Identifier: Unlicense
//THIS CONTRACT IS FOR TESTING PURPOSES AND GOOD VIBES ONLY
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MockNFTPolygon is ERC721Enumerable, Ownable {
    string[] mockTokenURI = [
        "ipfs://QmaAY3aQe8a8tDt24RaQtQX7pMGRQoarGF6pVYn5cpLyLX/",
        "ipfs://QmVoe89fH1xCAC51Q5oRb2VLmVg8VncYU37rv7TLxCuTQD/",
        "https://api.sunflower-land.com/nfts/farm/"
    ];

    constructor(address[] memory _owners, uint256 _amount) ERC721("Mock NFT", "mNFT") {
        //mint mock to owner
        for (uint256 j = 0; j < _owners.length; j++) {
            for (uint256 i = 0; i < _amount; i++) {
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
