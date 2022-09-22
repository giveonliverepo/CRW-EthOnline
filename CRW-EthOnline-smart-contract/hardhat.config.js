require("dotenv").config();
require("solidity-coverage");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_MAINNET_URL,
        enabled: true,
      },
    },
    mumbai: {
      url: process.env.ALCHEMY_MUMBAI_URL || "",
      accounts: [process.env.PRIVATE_KEY],
    },
    "optimism-goerli": {
      chainId: 420,
      url: process.env.ALCHEMY_OPTGOERLI_MUMBAI_URL || "",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      "optimism-goerli": process.env.OPTGOERLI_API_KEY,
    },
    customChains: [
      {
        network: "optimism-goerli",
        chainId: 420,
        urls: {
          apiURL: "https://api-goerli-optimism.etherscan.io/api",
          browserURL: "https://goerli-optimism.etherscan.io",
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
  },
};
