import { ethers, waffle } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
import { PrivateAirdrop } from "../typechain";
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

  console.log(`Airdrop Factory deployed to ${airdrop.address}`)

}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
