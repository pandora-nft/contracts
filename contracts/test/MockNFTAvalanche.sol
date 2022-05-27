//SPDX-License-Identifier: Unlicense
//THIS CONTRACT IS FOR TESTING PURPOSES AND GOOD VIBES ONLY
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MockNFTAvalanche is ERC721Enumerable, Ownable {
    string[] mockTokenURI = [
        "https://avaxpunks.com/punk/",
        "https://us.avaxtars.com/api/avatar/",
        "https://www.joyboysnft.com/character/",
        "ipfs://QmSDXbB8o7Jtiz8SHDpNTqNJThNN4rYzgs2WJpU5gDQJ1E/"
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
