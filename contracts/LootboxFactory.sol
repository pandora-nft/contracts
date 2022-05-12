//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Lootbox.sol";

contract LootboxFactory is Ownable, KeeperCompatible, VRFConsumerBaseV2 {
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
 
    mapping(uint256 => address) public lootboxAddress;
    uint256 public totalLootbox = 0;

    uint64 public s_subscriptionId;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // map lootbox to requestIds
    mapping(uint256 => uint256) private s_lootbox;

    constructor(
        address _vrfCoordinator,
        address _linkTokenContract,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_linkTokenContract);
        keyHash = _keyHash;
        createNewSubscription();
    }

    // VRF
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function requestRandomWords(uint32 _numWords, uint256 _lootboxId) internal {
        // Will revert if subscription is not set and funded.
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _numWords
        );
        s_lootbox[s_requestId] = _lootboxId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        Lootbox(lootboxAddress[s_lootbox[requestId]]).draw(randomWords);
    }

    function withdrawLink(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    //TODO Register Upkeep
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
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

    function performUpkeep(bytes calldata performData) external override {
        uint256 toDrawn = abi.decode(performData, (uint256));
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (
            !Lootbox(lootboxAddress[toDrawn]).isDrawn() &&
            Lootbox(lootboxAddress[toDrawn]).drawTimestamp() < block.timestamp
        ) {
            requestRandomWords(
                uint32(Lootbox(lootboxAddress[toDrawn]).numNFT()),
                toDrawn
            );
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
