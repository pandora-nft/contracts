pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract Ticket is ERC721 {
    constructor() ERC721("Pandora Ticket","PNDR") {

    }
    //TODO tokenURI function

    //TODO can only mint from lootbox
    function mint(address _to, uint256 _tokenId) public {
        _safeMint(_to, _tokenId);
    }
}