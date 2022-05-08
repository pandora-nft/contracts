//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lootbox is Ownable, ERC721Holder {
    uint256 public drawTimestamp;
    uint256 public ticketPrice;
    uint256 public minimumTicketRequired = 0;
    uint256 public maxTicketPerWallet = type(uint256).max;
    uint256 public ticketSold = 0;
    bool public isDrawn = false;
    address factory;
    mapping(uint256 => address) public ticketOwners;

    constructor(
        uint256 _drawTimestamp,
        uint256 _ticketPrice,
        uint256 _minimumTicketRequired
    ) {
        drawTimestamp = _drawTimestamp;
        ticketPrice = _ticketPrice;
        minimumTicketRequired = _minimumTicketRequired;
        factory = msg.sender;
    }

    function draw() public {
        require(msg.sender == factory, "Unauthorized");
        //TODO draw logic
        isDrawn = true;
    }

    function depositNFTs(IERC721 _nft, uint256[] calldata _tokenIds)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }
    }

    function buyTickets(uint256 _amount) public payable {
        require(
            _amount <= maxTicketPerWallet,
            "Max ticket per wallet is reached"
        );
        require(msg.value == ticketPrice * _amount, "Incorrect amount");
        //TODO mint ticket to buyer
        ticketOwners[ticketSold] = msg.sender;
        ticketSold += _amount;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
