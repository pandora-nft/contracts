import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { FunctionFragment } from "ethers/lib/utils";
import { ethers, network } from "hardhat";
import { GAS_LANE, LINK_TOKEN, VRF_COORDINATOR } from "../constants/chainlink";

// snippet for testing time-based functions
// await ethers.provider.send('evm_increaseTime', [seconds]);
// await ethers.provider.send('evm_mine');

describe("LootboxFactory", function () {
  let vrfCoordinatorV2Address: string;
  let linkTokenAddress: string;
  const ONE_LINK = "1000000000000000000";
  const POINT_ONE_LINK = "100000000000000000";

  let accounts: SignerWithAddress[];
  let chainId: number | undefined;
  let deployerAddress: string;

  let LinkToken: ContractFactory;
  let VRFCoordinatorV2Mock: ContractFactory;
  let LootboxFactory: ContractFactory;

  let lootboxFactory: Contract;
  let lootbox: Contract;
  let ticket: Contract;

  let lootboxAddress: string;
  let drawTime: number;
  before(async function () {
    accounts = await ethers.getSigners();
    chainId = network.config.chainId;
    deployerAddress = accounts[0].address;
    LootboxFactory = await ethers.getContractFactory("LootboxFactory");
    lootboxFactory = await LootboxFactory.deploy(
      VRF_COORDINATOR[4],
      LINK_TOKEN[4],
      GAS_LANE[4]
    );
    await lootboxFactory.deployed();
    drawTime = Math.floor(Date.now() / 1000) + 3600;
    await lootboxFactory
      .connect(accounts[1])
      ["deployLootbox(string,uint256,uint256,uint256)"](
        "Test lootbox",
        drawTime,
        ethers.utils.parseEther("0.01"),
        ethers.utils.parseEther("0")
      );
    lootboxAddress = await lootboxFactory.lootboxAddress("0");
    lootbox = await ethers.getContractAt("Lootbox", lootboxAddress);
    ticket = await ethers.getContractAt(
      "PandoraTicket",
      await lootboxFactory.ticketAddress()
    );
  });
  describe("Check variables", function () {
    it("Should set lootbox owner to deployer", async function () {
      expect(await lootboxFactory.owner()).to.equal(deployerAddress);
    });

    it("Should set Ticket owner to deployer", async function () {
      const pandoraTicket = await ethers.getContractAt(
        "PandoraTicket",
        await lootboxFactory.ticketAddress()
      );
      expect(await pandoraTicket.owner()).to.equal(deployerAddress);
    });

    it("Should get all loot boxes attributes", async function () {
      expect(await lootboxFactory.allLootboxes(0)).to.equal(lootboxAddress);
      const lootboxes = await lootboxFactory.getAllLootboxes();
      expect(lootboxes.length).to.equal(1);
      expect(lootboxes[0]).to.equal(lootboxAddress);
    });
  });

  describe("Lootbox variable", function () {
    it("Total lootbox should increase", async function () {
      expect(await lootboxFactory.totalLootbox()).to.equal("1");
    });

    it("Correct lootbox name", async function () {
      expect(await lootboxFactory.getLootboxName("0")).to.equal("Test lootbox");
    });

    it("lootbox Owned should increase", async function () {
      expect(
        (await lootboxFactory.getLootboxOwned(accounts[1].address)).length
      ).to.equal(1);
    });

    it("Lootbox variable deployed correctly", async function () {
      expect(await lootbox.drawTimestamp()).to.equal(drawTime);
    });
  });
  //TODO test more about buying ticket
  describe("Try minting 2 tickets", function () {
    before(async function () {
      const tx = await lootbox.connect(accounts[1]).buyTickets(2, {
        value: ethers.utils.parseEther("0.02"),
      });
      const receipt = await tx.wait();
      // console.log(receipt);
    });
    it("Should mint a ticket", async function () {
      console.log(await ticket.tokenURI(1));
      expect(await ticket.totalSupply()).to.equal(2);
      expect(await ticket.tokenOfOwnerByIndex(accounts[1].address, 1)).to.equal(
        1
      );
    });
  });

  describe("Try depositing", function () {
    before(async function () {
      await lootbox.connect(accounts[1]).buyTickets(3, {
        value: ethers.utils.parseEther("0.03"),
      });
      await ticket
        .connect(accounts[1])
        .setApprovalForAll(lootbox.address, true);
      const tx = await lootbox
        .connect(accounts[1])
        .depositNFTs(ticket.address, [2, 3]);
      const receipt = await tx.wait();
      console.log(receipt);
    });
    it("NFT should be in lootbox", async function () {
      expect(await ticket.balanceOf(lootboxAddress)).to.equal(2);
    });
  });
});
