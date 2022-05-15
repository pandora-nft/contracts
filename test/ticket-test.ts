import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { FunctionFragment } from "ethers/lib/utils";
import { ethers, network } from "hardhat";
import { GAS_LANE, LINK_TOKEN, VRF_COORDINATOR } from "../constants/chainlink";

// snippet for testing time-based functions
// await ethers.provider.send('evm_increaseTime', [seconds]);
// await ethers.provider.send('evm_mine');

describe("Ticket", function () {
})
