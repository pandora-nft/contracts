import { LOOTBOX_FACTORY } from "../constants/address";
import { ethers, network } from "hardhat";

const deployLootbox = async () => {
  const drawTime = new Date(Date.now() + 3600 * 24 * 2).getTime();

  const LootboxFactory = await ethers.getContractFactory("LootboxFactory");
  const lootboxFactory = await LootboxFactory.attach(LOOTBOX_FACTORY[97]);

  const tx = await lootboxFactory[
    "deployLootbox(string,uint256,uint256,uint256)"
  ](
    "gm",
    drawTime,
    ethers.utils.parseEther("0.01"),
    ethers.utils.parseEther("0")
  );
  await tx.wait();

  const lootboxAddress = (await lootboxFactory.functions.lootboxAddress(0))[0];

  console.log("new lootbox deployed at", lootboxAddress);
};

deployLootbox();
