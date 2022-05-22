
import { ethers, network } from "hardhat";
import { MOCK_NFT, TEST_LOOTBOX, TICKET } from "../constants/address";
async function main() {
  const accounts = await ethers.getSigners();
  const chainId = network.config.chainId;
  const lootbox = await ethers.getContractAt("Lootbox", TEST_LOOTBOX[chainId!]);
  const ticket = await ethers.getContractAt("PandoraTicket", TICKET[chainId!]);
  
  const mockNFT = await ethers.getContractAt("SuperRare", MOCK_NFT[chainId!]);

  const approval = await mockNFT.setApprovalForAll(
    TEST_LOOTBOX[chainId!],
    true
  )

  approval.wait().then(() => {


    lootbox.depositNFTs(
      [
        // [TICKET[chainId!], 0],
        // [TICKET[chainId!], 1],
        //mockNFT on mumbai
        [MOCK_NFT[chainId!], 1],
        [MOCK_NFT[chainId!], 2],
        [MOCK_NFT[chainId!], 3],
        [MOCK_NFT[chainId!], 4],

      ]
    ).then(console.log())

  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
