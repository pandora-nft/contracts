import { ethers, network } from "hardhat";
import { LOOTBOX_FACTORY, TEST_LOOTBOX, TICKET } from "../constants/address";
async function main() {
    const accounts = await ethers.getSigners();
    const chainId = network.config.chainId;

    const lootbox = await ethers.getContractAt("Lootbox", TEST_LOOTBOX[chainId!]);
    
    await lootbox.buyTickets(5, { value: ethers.utils.parseEther("0.05") });
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  