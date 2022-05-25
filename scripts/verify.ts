// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, network } from "hardhat";
import { LOOTBOX_FACTORY, TEST_LOOTBOX, TICKET } from "../constants/address";
const hre = require("hardhat");
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
  // Input
  const lootbox = await ethers.getContractAt("Lootbox", TEST_LOOTBOX[chainId!]);
  const boxName = "Hype"
  try {

    await hre.run("verify:verify", {
      address: LOOTBOX_FACTORY[chainId!],
      constructorArguments: [
        vrfCoordinatorV2Address,
        linkTokenAddress,
        gasLane,
      ],
    });
  } catch {
    console.log()
  }
  try {

    await hre.run("verify:verify", {
      address: TEST_LOOTBOX[chainId!],
      constructorArguments: [
        boxName,
        0,
        await lootbox.drawTimestamp(),
        ethers.utils.parseEther("0.01"),
        ethers.utils.parseEther("0"),
        ethers.constants.MaxUint256,
        TICKET[chainId!],
      ],
    })

  } catch {
    console.log()
  }
  try {
    await hre.run("verify:verify", {
      address: TICKET[chainId!],
      constructorArguments: [
        LOOTBOX_FACTORY[chainId!],
      ],
    })
  } catch {
    console.log()
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
