//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./LootboxFactory.sol";
import "./PandoraTicket.sol";

error Lootbox__Unauthorized();
error Lootbox__AlreadyDrawn();
error Lootbox__NotDrawnYet();
error Lootbox__NotEnoughRandomWords();
error Lootbox__ExceedMaxTicketsPerWallet();
error Lootbox__NotEnoughEth();
error Lootbox__NoTicketToRefund();
error Lootbox__NotRefundable();
error Lootbox__TooManyNFTsDeposited();

contract Lootbox is Ownable, ERC721Holder {
    uint256 public drawTimestamp;
    uint256 public ticketPrice;
    uint256 public minimumTicketRequired;
    uint256 public maxTicketPerWallet;

    uint256 immutable maxNFT = 500;
    uint256 public ticketSold = 0;
    uint256 public numNFT = 0;
    bool public isDrawn = false;
    bool public isRefundable = false;
    address factory;
    string public name;
    uint256 public id;
    address ticket;
    struct NFT {
        address _address;
        uint256 _tokenId;
    }

    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => uint256) public winners;
    mapping(uint256 => uint256) public wonTicket;

    event NFTSDeposited(NFT[] nfts);
    event Drawn(uint256[] winnerTickets);
    constructor(
        string memory _name,
        uint256 _id,
        uint256 _drawTimestamp,
        uint256 _ticketPrice,
        uint256 _minimumTicketRequired,
        uint256 _maxTicketPerWallet,
        address _ticket
    ) {
        name = _name;
        id = _id;
        drawTimestamp = _drawTimestamp;
        ticketPrice = _ticketPrice;
        minimumTicketRequired = _minimumTicketRequired;
        maxTicketPerWallet = _maxTicketPerWallet;
        factory = msg.sender;
        ticket = _ticket;
    }

    function draw(uint256[] memory _randomWords) public {
        if (msg.sender != factory) {
            revert Lootbox__Unauthorized();
        }
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (_randomWords.length != numNFT) {
            revert Lootbox__NotEnoughRandomWords();
        }
        if (ticketSold <= minimumTicketRequired || ticketSold < numNFT) {
            isRefundable = true;
        } else {
            uint256[] memory _winners = new uint256[](numNFT);
            uint256 i = 0;
            while (i < numNFT) {
                uint256 winnerTicketId = PandoraTicket(ticket).ticketIds(
                    id,
                    _randomWords[i] % ticketSold
                );
                if (PandoraTicket(ticket).isWinner(winnerTicketId) == false) {
                    LootboxFactory(factory).setWinner(winnerTicketId, id);
                    winners[i] = winnerTicketId;
                    wonTicket[winnerTicketId] = i;
                    _winners[i] = winnerTicketId;
                    i++;
                }
            }
            emit Drawn(_winners);
        }
        isDrawn = true;
    }

    function depositNFTs(NFT[] memory _nfts) public onlyOwner {
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (numNFT + _nfts.length > maxNFT) {
            revert Lootbox__TooManyNFTsDeposited();
        }
        for (uint256 i = 0; i < _nfts.length; i++) {
            IERC721(_nfts[i]._address).safeTransferFrom(
                msg.sender,
                address(this),
                _nfts[i]._tokenId
            );
            NFTs[numNFT]._address = _nfts[i]._address;
            NFTs[numNFT]._tokenId = _nfts[i]._tokenId;
            ++numNFT;
        }
        emit NFTSDeposited(_nfts);
    }

    function buyTickets(uint256 _amount) public payable {
        if (isDrawn) {
            revert Lootbox__AlreadyDrawn();
        }
        if (_amount > maxTicketPerWallet) {
            revert Lootbox__ExceedMaxTicketsPerWallet();
        }
        if (msg.value != ticketPrice * _amount) {
            revert Lootbox__NotEnoughEth();
        }

        LootboxFactory(factory).mintTicket(msg.sender, _amount, id);
        ticketSold += _amount;
    }

    function refund(uint256[] memory tokenIds) public {
        if (!isRefundable) {
            revert Lootbox__NotRefundable();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (PandoraTicket(ticket).ownerOf(tokenIds[i]) != msg.sender) {
                revert Lootbox__Unauthorized();
            }
            if (PandoraTicket(ticket).isRefunded(tokenIds[i])) {
                revert Lootbox__NotRefundable();
            }
        }
        LootboxFactory(factory).refundTicket(tokenIds, id);
        payable(msg.sender).transfer(ticketPrice * tokenIds.length);
    }

    function claimNFT(uint256 _ticketId) public {
        if (!isDrawn) {
            revert Lootbox__NotDrawnYet();
        }
        if (PandoraTicket(ticket).ownerOf(_ticketId) != msg.sender) {
            revert Lootbox__Unauthorized();
        }
        if (PandoraTicket(ticket).isClaimed(_ticketId)) {
            revert Lootbox__Unauthorized();
        }

        IERC721(NFTs[wonTicket[_ticketId]]._address).safeTransferFrom(
            address(this),
            msg.sender,
            NFTs[wonTicket[_ticketId]]._tokenId
        );
        LootboxFactory(factory).setClaim(_ticketId, id);
    }

    function withdraw() public onlyOwner {
        if (!isDrawn) {
            revert Lootbox__NotDrawnYet();
        }
        if (isRefundable) {
            revert Lootbox__Unauthorized();
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawNFT() public onlyOwner {
        if (!isRefundable) {
            revert Lootbox__NotRefundable();
        }
        for (uint256 i; i < numNFT; i++) {
            IERC721(NFTs[i]._address).safeTransferFrom(
                address(this),
                msg.sender,
                NFTs[i]._tokenId
            );
        }
    }

    function getAllNFTs() public view returns (NFT[] memory) {
        NFT[] memory nfts = new NFT[](numNFT);
        for (uint256 i = 0; i < numNFT; i++) {
            nfts[i] = NFTs[i];
        }
        return nfts;
    }
}
