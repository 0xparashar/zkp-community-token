
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";

export default {
  solidity: {
	compilers: [
		{
			version: "0.8.0",
			settings: {
				optimizer: {
					enabled: true,
					runs: 88888
				}
			}
		},
		{
			version: "0.8.1",
			settings: {
				optimizer: {
					enabled: true,
					runs: 88888
				}
			}
		}
	]

  },
  mocha: {
    timeout: 200000
  }
};
