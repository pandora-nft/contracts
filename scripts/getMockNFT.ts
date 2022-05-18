
// Runtime Environment's members available in the global scope.
import { ethers, network } from "hardhat";
async function main() {

  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const deployerAddress = accounts[0].address;

  // We get the contract to deploy
  const SuperRare = await ethers.getContractFactory("SuperRare");
  const superRare = await SuperRare.deploy();
  await superRare.deployed();

  console.log("mock NFT deployed at", superRare.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
