
// Runtime Environment's members available in the global scope.
import { ContractFactory } from "ethers";
import { ethers, network } from "hardhat";
async function main() {

  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const deployerAddress = accounts[0].address;

  let MockNFT: ContractFactory;
  // We get the contract to deploy
  if (chainId === 80001) {
    MockNFT = await ethers.getContractFactory("MockNFTPolygon");
  }
  if (chainId === 97) {
    MockNFT = await ethers.getContractFactory("MockNFTBSC");
  }
  if (chainId === 43113) {
    MockNFT = await ethers.getContractFactory("MockNFTAvalanche");
  }

  const mockNFT = await MockNFT!.deploy(
    [
      // "0x31d003F229fabc4dC9404dFFe3FEc2698cc8F0ab",
      // "0xafF2671aD7129DC23D05F83fF651601e9d1aea0a",
      "0x5f958971072bf53C4C577b44d7a8a04ADce904Ba",
    ],
    40
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
