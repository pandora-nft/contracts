
// Runtime Environment's members available in the global scope.
import { ContractFactory } from "ethers";
import { ethers, network } from "hardhat";
async function main() {

  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const deployerAddress = accounts[0].address;

  let SuperRare: ContractFactory;
  // We get the contract to deploy
  SuperRare = await ethers.getContractFactory("SuperRare");

  const mockNFT = await SuperRare!.deploy(
  );
  await mockNFT.deployed();

  console.log("mock NFT deployed at", mockNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
