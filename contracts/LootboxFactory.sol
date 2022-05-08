//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Lootbox.sol";

contract LootboxFactory is Ownable, KeeperCompatible {
    mapping(uint256 => address) public lootboxAddress;
    uint256 totalLootbox = 0;
    constructor() {}

    //TODO Register Upkeep
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[] memory toDrawn;
        for (uint256 i = 0; i < totalLootbox; i++) {
            if (
                !Lootbox(lootboxAddress[i]).isDrawn() &&
                Lootbox(lootboxAddress[i]).drawTimestamp() < block.timestamp
            ) {
                upkeepNeeded = true;
                performData = abi.encode(i);
                break;
            }
        }
    }

    //TODO draw function
    function performUpkeep(bytes calldata performData) external override {
        uint256 toDrawn = abi.decode(performData, (uint256));
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (
            !Lootbox(lootboxAddress[toDrawn]).isDrawn() &&
            Lootbox(lootboxAddress[toDrawn]).drawTimestamp() < block.timestamp
        ) {
            Lootbox(lootboxAddress[toDrawn]).draw();
        }
    }

    function deployLootbox(
        uint256 _drawTimestamp,
        uint256 _ticketPrice,
        uint256 _minimumTicketRequired
    ) public {
        Lootbox lootbox = new Lootbox(
            _drawTimestamp,
            _ticketPrice,
            _minimumTicketRequired
        );
        lootbox.transferOwnership(msg.sender);
        lootboxAddress[totalLootbox] = address(lootbox);
        totalLootbox++;
    }
}
