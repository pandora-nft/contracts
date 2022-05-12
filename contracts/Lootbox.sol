//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

error Lootbox__Unauthorized();
error Lootbox__AlreadyDrawn();
error Lootbox__NotDrawnYet();
error Lootbox__NotEnoughRandomWords();
error Lootbox__ExceedMaxTicketsPerWallet();
error Lootbox__NotEnoughEth();
error Lootbox__NoTicketToRefund();
error Lootbox__NotRefundable();

contract Lootbox is Ownable, ERC721Holder {
    uint256 public drawTimestamp;
    uint256 public ticketPrice;
    uint256 public minimumTicketRequired = 0;
    uint256 public maxTicketPerWallet = type(uint256).max;
    uint256 public ticketSold = 0;
    uint256 public numNFT = 0;
    bool public isDrawn = false;
    bool public isRefundable = false;
    address factory;
    struct NFT {
        address _address;
        uint256 _tokenId;
    }
    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => address) public winners;
    mapping(uint256 => address) public ticketOwners;
    mapping(address => uint256) public numTickets;

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

    function draw(uint256[] memory _randomWords) public {
        if (msg.sender != factory) {
            revert Lootbox__Unauthorized();
        }
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (_randomWords.length != numNFT) {
            // not sure if we should use >= ??
            revert Lootbox__NotEnoughRandomWords();
        }

        if (ticketSold <= minimumTicketRequired) {
            isRefundable = true;
        } else {
            for (uint256 i; i < numNFT; i++) {
                winners[i] = ticketOwners[_randomWords[i] % ticketSold];
            }
        }
        isDrawn = true;
    }

    function depositNFTs(IERC721 _nft, uint256[] calldata _tokenIds)
        public
        onlyOwner
    {
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            NFTs[numNFT]._address = address(_nft);
            NFTs[numNFT]._tokenId = _tokenIds[i];
            ++numNFT;
        }
    }

    function buyTickets(uint256 _amount) public payable {
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (_amount > maxTicketPerWallet) {
            revert Lootbox__ExceedMaxTicketsPerWallet();
        }
        if (msg.value < ticketPrice * _amount) {
            revert Lootbox__NotEnoughEth();
        }

        //TODO mint ticket to buyer
        ticketOwners[ticketSold] = msg.sender;
        numTickets[msg.sender] += _amount;
        ticketSold += _amount;
    }

    function refund() public {
        if (numTickets[msg.sender] == 0) {
            revert Lootbox__NoTicketToRefund();
        }
        if (!isRefundable) {
            revert Lootbox__NotRefundable();
        }
        numTickets[msg.sender] = 0;
        payable(msg.sender).transfer(ticketPrice * numTickets[msg.sender]);
    }

    function getPrizeWon(address player) public view returns (NFT[] memory) {
        NFT[] memory prizes = new NFT[](numNFT);
        uint256 count = 0;
        for (uint256 i = 0; i < numNFT; i++) {
            if (winners[i] == player) {
                prizes[count] = NFTs[i];
                count++;
            }
        }
        return prizes;
    }

    function claimNFT(uint256 id) public {
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (winners[id] != msg.sender) {
            revert Lootbox__Unauthorized();
        }
        IERC721(NFTs[id]._address).safeTransferFrom(
            address(this),
            msg.sender,
            NFTs[id]._tokenId
        );
    }

    function withdraw() public onlyOwner {
        if (isDrawn) {
            revert Lootbox__NotDrawnYet();
        }
        payable(msg.sender).transfer(address(this).balance);
    }
}
