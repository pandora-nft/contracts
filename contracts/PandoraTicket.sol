//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./LootboxFactory.sol";
import "./Lootbox.sol";

error Ticket__Unauthorized();

contract PandoraTicket is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    LootboxFactory factory;
    mapping(uint256 => uint256) public lootboxIds;
    mapping(uint256 => uint256[]) public ticketIds;

    mapping(uint256 => bool) public isWinner;
    mapping(uint256 => bool) public isRefunded;
    mapping(uint256 => bool) public isClaimed;

    Counters.Counter public tokenIdCounter;
    string imageURI =
        "ipfs://bafkreigm5ir7vyiricnl23a7bbbzi3ve2tr6v54pi2qusvfuy2rlduc3we";
    string winnerImageURI =
        "ipfs://bafybeiaiox6eon5rfjm3mb3742xiowt7tpny73rtmryrqdxmoulct5jina";
    string refundedImageURI = "ipfs://bafkreie45upygj2otdncycdl2fluqmyqvxme7j6xsi6zv6ndzrqcarsp6u";
    string claimedImageURI = "ipfs://bafkreic4x7lbwa7lo3vgxk2rgr46nbuwro2iadcdurn75mxo3v4jzw6fxq";
    string refundableImageURI = "ipfs://bafkreiazlrn5mr2s3d5r24acmopzuezsgi7s6amx2m3bpn6mvekgd5gc7e";
    string expiredImageURI = "ipfs://bafkreifcfs36qp7tt6xmmyrtj2dqoytfhfo6bcub47csbanwutl2gcuahu";

    event TicketMinted(uint256 indexed tokenId, address to, uint256 lootboxId);

    constructor(address _factory) ERC721("The Pandora Ticket", "PANDORA") {
        factory = LootboxFactory(_factory);
    }

    function getTicketsForLootbox(uint256 lootboxId)
        public
        view
        returns (uint256[] memory)
    {
        return ticketIds[lootboxId];
    }

    function getOwnTicketsForLootbox(uint256 lootboxId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tickets = getTicketsForLootbox(lootboxId);
        uint256[] memory ownTickets = new uint256[](tickets.length);
        uint256 count = 0;
        for (uint256 i; i < tickets.length; i++) {
            if (ownerOf(tickets[i]) == msg.sender) {
                ownTickets[count] = tickets[i];
                ++count;
            }
        }
        return ownTickets;
    }

    function boolToInt(bool _bool) internal pure returns (uint256) {
        if (_bool) {
            return 1;
        } else {
            return 0;
        }
    }

    //!Please ignore Linter error below
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _imageURI = "";
        string memory _description = "";
        if (
            !Lootbox(
                LootboxFactory(factory).lootboxAddress(lootboxIds[tokenId])
            ).isDrawn()
        ) {
            _imageURI = imageURI;
            _description = "! You have a chance to win prizes inside the Pandora Box!";
        } else {
            if (
                Lootbox(
                    LootboxFactory(factory).lootboxAddress(lootboxIds[tokenId])
                ).isRefundable()
            ) {
                if (isRefunded[tokenId]) {
                    _imageURI = refundedImageURI;
                    _description = "! You have already been refunded for this ticket.";
                } else {
                    _imageURI = refundableImageURI;
                    _description = "! This ticket can be refunded";
                }
            } else {
                if (isWinner[tokenId]) {
                    if (isClaimed[tokenId]) {
                        _imageURI = claimedImageURI;
                        _description = "! This ticket have already been claimed for a prize.";
                    } else {
                        _imageURI = winnerImageURI;
                        _description = "! Congratulations, You have won NFT prize. Claim it now!";
                    }
                } else {
                    _imageURI = expiredImageURI;
                }
            }
        }
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"The Pandora Ticket #',
                                Strings.toString(tokenId),
                                '", "description":"',
                                "This ticket is generated from Lootbox #",
                                Strings.toString(lootboxIds[tokenId]),
                                ": ",
                                factory.getLootboxName(lootboxIds[tokenId]),
                                _description,
                                '", "isWinner": "',
                                Strings.toString(boolToInt(isWinner[tokenId])),
                                '", "isRefunded": "',
                                Strings.toString(
                                    boolToInt(isRefunded[tokenId])
                                ),
                                '", "drawTimestamp":"',
                                Strings.toString(
                                    Lootbox(
                                        factory.lootboxAddress(
                                            lootboxIds[tokenId]
                                        )
                                    ).drawTimestamp()
                                ),
                                '", "image": "',
                                _imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function mint(
        address _to,
        uint256 _amount,
        uint256 _lootboxId
    ) public {
        if (msg.sender != address(factory)) {
            revert Ticket__Unauthorized();
        }
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, tokenId);
            lootboxIds[tokenId] = _lootboxId;
            ticketIds[_lootboxId].push(tokenId);
            emit TicketMinted(tokenId, _to, _lootboxId);
        }
    }

    function setWinner(uint256 _tokenId) public {
        if (msg.sender != address(factory)) {
            revert Ticket__Unauthorized();
        }
        isWinner[_tokenId] = true;
    }

    function refundTicket(uint256[] memory tokenIds) public {
        if (msg.sender != address(factory)) {
            revert Ticket__Unauthorized();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isRefunded[tokenIds[i]] = true;
        }
    }

    function setClaim(uint256 _tokenId) public {
        if (msg.sender != address(factory)) {
            revert Ticket__Unauthorized();
        }
        if (isWinner[_tokenId] == false) {
            revert Ticket__Unauthorized();
        }
        isClaimed[_tokenId] = true;
    }
}
