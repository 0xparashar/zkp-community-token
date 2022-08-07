import { ethers, waffle } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
import { PoolManager__factory, PrivateAirdrop, PrivateAirdrop__factory } from "../typechain";
import { readMerkleTreeAndSourceFromFile } from "../utils/TestUtils";
import { toHex } from "zkp-merkle-airdrop-lib";

/**
 * Deploys a test set of contracts: ERC20, Verifier, PrivateAirdrop and transfers some ERC20 to the
 * PrivateAirdrop contract.
 */
async function main() {
  // PARAMS

  let [signer] = await ethers.getSigners();

  let plonkFactory = await ethers.getContractFactory("PlonkVerifier");
  let plonk = await plonkFactory.deploy();
  console.log(`PlonkVerifier contract address: ${plonk.address}`);

  let airdropFactory = await ethers.getContractFactory(
    "PrivateAirdrop",
    signer
  );
  let airdrop: PrivateAirdrop = (await airdropFactory.deploy(
    plonk.address
  )) as PrivateAirdrop;
  
  // let airdrop = PrivateAirdrop__factory.connect("0x1C06B527816fAa767071Ec1Ded43934BDe4de585", signer);

  console.log(`Airdrop Factory deployed to ${airdrop.address}`)

  await airdrop.registerCommunity("Test Community");

  let Governor = await ethers.getContractFactory('Governor');
  let Timelock = await ethers.getContractFactory('Timelock');
  let governor = await Governor.deploy();
  let timelock = await Timelock.deploy();

  console.log(`Governor ${governor.address} && Timelock ${timelock.address}`)

  let PoolManager = await ethers.getContractFactory('PoolManager');
  
  let poolManager = await PoolManager.deploy(airdrop.address, governor.address, timelock.address);
  
  // let poolManager = PoolManager__factory.connect("0xaDc626Fe641C96fa2D96b89508c715d273ee7e43", signer);

  await poolManager.createPool(0, "Test Pool", "TPOOL1", ethers.utils.parseEther("10"), "0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844");

}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
