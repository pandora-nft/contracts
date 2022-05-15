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

  const ONE_LINK = "1000000000000000000";
  const POINT_ONE_LINK = "100000000000000000";
  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const deployerAddress = accounts[0].address;

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

  console.log("lootboxFactory deployed at:", lootboxFactory.address);

  //Top up with LINK Token
  // await lootboxFactory.topUpSubscription(
  //   ONE_LINK
  // )
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
