//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Lootbox.sol";
import "./PandoraTicket.sol";

contract LootboxFactory is Ownable, KeeperCompatible, VRFConsumerBaseV2 {
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    PandoraTicket ticket;
    mapping(uint256 => address) public lootboxAddress;
    mapping(address => uint256[]) public lootboxOwned;
    address[] public allLootboxes;
    uint256 public totalLootbox = 0;
    uint64 public s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable gasLane;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 immutable callbackGasLimit = 500000;

    // The default is 3, but you can set this higher.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    // map lootbox to requestIds
    mapping(uint256 => uint256) private s_lootbox;

    constructor(
        address _vrfCoordinator,
        address _linkTokenContract,
        bytes32 _gasLane
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_linkTokenContract);
        gasLane = _gasLane;
        createNewSubscription();
        ticket = new PandoraTicket(address(this));
        ticket.transferOwnership(msg.sender);
    }

    //getter
    function getLootboxName(uint256 _lootboxId)
        public
        view
        returns (string memory)
    {
        return Lootbox(lootboxAddress[_lootboxId]).name();
    }

    function ticketAddress() public view returns (address) {
        return address(ticket);
    }

    function getLootboxOwned(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return lootboxOwned[_owner];
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
            gasLane,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
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
        string memory _name,
        uint256 _drawTimestamp,
        uint256 _ticketPrice,
        uint256 _minimumTicketRequired,
        uint256 _maxTicketPerWallet
    ) public {
        Lootbox lootbox = new Lootbox(
            _name,
            totalLootbox,
            _drawTimestamp,
            _ticketPrice,
            _minimumTicketRequired,
            _maxTicketPerWallet,
            address(ticket)
        );
        lootbox.transferOwnership(msg.sender);
        lootboxAddress[totalLootbox] = address(lootbox);
        lootboxOwned[msg.sender].push(totalLootbox);
        allLootboxes.push(address(lootbox));
        totalLootbox++;
    }

    function deployLootbox(
        string memory _name,
        uint256 _drawTimestamp,
        uint256 _ticketPrice,
        uint256 _minimumTicketRequired
    ) public {
        Lootbox lootbox = new Lootbox(
            _name,
            totalLootbox,
            _drawTimestamp,
            _ticketPrice,
            _minimumTicketRequired,
            type(uint256).max,
            address(ticket)
        );
        lootbox.transferOwnership(msg.sender);
        lootboxAddress[totalLootbox] = address(lootbox);
        lootboxOwned[msg.sender].push(totalLootbox);
        allLootboxes.push(address(lootbox));
        totalLootbox++;
    }

    function mintTicket(
        address _to,
        uint256 _amount,
        uint256 _lootboxId
    ) public {
        if (msg.sender != lootboxAddress[_lootboxId]) {
            revert("Unauthorized");
        }
        ticket.mint(_to, _amount, _lootboxId);
    }

    function refundTicket(uint256[] memory _tokenIds, uint256 _lootboxId)
        public
    {
        if (msg.sender != lootboxAddress[_lootboxId]) {
            revert("Unauthorized");
        }
        ticket.refundTicket(_tokenIds);
    }

    function setWinner(uint256 _tokenId, uint256 _lootboxId) public {
        if (msg.sender != lootboxAddress[_lootboxId]) {
            revert("Unauthorized");
        }
        ticket.setWinner(_tokenId);
    }

    function setClaim(uint256 _tokenId, uint256 _lootboxId) public {
        if (msg.sender != lootboxAddress[_lootboxId]) {
            revert("Unauthorized");
        }
        ticket.setClaim(_tokenId);
    }

    function getAllLootboxes() public view returns (address[] memory) {
        return allLootboxes;
    }

    // code size exceed
    // function getLootboxesOwnedByUser(address _user)
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     uint256[] memory lootboxIds = getLootboxOwned(_user);

    //     address[] memory lootboxes = new address[](lootboxIds.length);
    //     for (uint256 i = 0; i < lootboxIds.length; i++) {
    //         uint256 lootboxId = lootboxIds[i];
    //         lootboxes[i] = allLootboxes[lootboxId];
    //     }
    //     return lootboxes;
    // }
}
