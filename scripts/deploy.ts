// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, network } from "hardhat";
import { VRF_COORDINATOR, LINK_TOKEN, GAS_LANE } from "../constants/chainlink";
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const deployerAddress = accounts[0].address;
  console.log("Deploying with ", deployerAddress);
  console.log("ChainId: ", chainId);
  let vrfCoordinatorV2Address, linkTokenAddress, gasLane
  if (chainId == 31337) {
    vrfCoordinatorV2Address = VRF_COORDINATOR[4];
    linkTokenAddress = LINK_TOKEN[4];
    gasLane = GAS_LANE[4];

  } else {
    vrfCoordinatorV2Address = VRF_COORDINATOR[chainId!];
    linkTokenAddress = LINK_TOKEN[chainId!];
    gasLane = GAS_LANE[chainId!];
  }
  // We get the contract to deploy
  const LootboxFactory = await ethers.getContractFactory("LootboxFactory");
  const lootboxFactory = await LootboxFactory.deploy(
    vrfCoordinatorV2Address,
    linkTokenAddress,
    gasLane,
  );
  await lootboxFactory.deployed();  
  const linkToken = await ethers.getContractAt("LinkTokenInterface", linkTokenAddress);
  console.log("lootboxFactory deployed at:", lootboxFactory.address);
  console.log("ticket Address", await lootboxFactory.ticketAddress());
  // Top up with LINK Token
  await linkToken.increaseApproval(lootboxFactory.address, ethers.utils.parseEther("1"));
  await lootboxFactory.topUpSubscription(
    ethers.utils.parseEther("1")
  )


  const drawTime = Math.floor(Date.now() / 1000) + 3600;
  await lootboxFactory["deployLootbox(string,uint256,uint256,uint256)"](
      "Test lootbox",
      drawTime,
      ethers.utils.parseEther("0.01"),
      ethers.utils.parseEther("0")
  );
  const lootboxAddress = await lootboxFactory.lootboxAddress("0");

  console.log("lootbox 0 ",await lootboxFactory.getLootboxName(0)," deployed at", lootboxAddress);


  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
