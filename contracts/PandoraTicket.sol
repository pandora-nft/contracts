//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./LootboxFactory.sol";

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
    string public imageURI =
        "ipfs://bafkreigm5ir7vyiricnl23a7bbbzi3ve2tr6v54pi2qusvfuy2rlduc3we";

    constructor(address _factory) ERC721("The Pandora Ticket", "PANDORA") {
        factory = LootboxFactory(_factory);
    }

    //!Please ignore Linter error below
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"The Pandora Ticket #"',
                                Strings.toString(tokenId),
                                '", "description":"',
                                "This ticket is generated from Lootbox #",
                                Strings.toString(lootboxIds[tokenId]),
                                ": ",
                                factory.getLootboxName(lootboxIds[tokenId]),
                                "! You have a chance to win prizes inside the Pandora Box!",
                                '", "image": "',
                                imageURI,
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
        if(isWinner[_tokenId]==false){
            revert Ticket__Unauthorized();
        }
        isClaimed[_tokenId] = true;
    }
}
