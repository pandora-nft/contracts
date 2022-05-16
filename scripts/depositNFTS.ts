
import { ethers, network } from "hardhat";
import { LOOTBOX_FACTORY, TEST_LOOTBOX, TICKET} from "../constants/address";
async function main() {
  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const lootbox = await ethers.getContractAt("Lootbox", TEST_LOOTBOX[chainId!]);
  const ticket = await ethers.getContractAt("PandoraTicket", TICKET[chainId!]);
  
  await ticket.setApprovalForAll(
    TEST_LOOTBOX[chainId!],
    true
  )

  await lootbox.depositNFTs(
      [
          [TICKET[chainId!],0],
          [TICKET[chainId!],1]
      ]
  )

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
