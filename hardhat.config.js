require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Load environment variables from .env

module.exports = {
  solidity: {
    version: "0.8.17", // Match the Solidity version used in your contracts
    settings: {
      optimizer: {
        enabled: true, // Enable the optimizer for smaller and more efficient bytecode
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {}, // Local Hardhat Network
    localhost: {
      url: "http://127.0.0.1:8545", // Local development blockchain
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL || "", // Infura/Alchemy RPC URL for Goerli
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], // Private key for deployment
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "", // Infura/Alchemy RPC URL for Ethereum Mainnet
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], // Private key for deployment
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "", // API Key for Etherscan verification
  },
  paths: {
    sources: "./contracts", // Your contract files
    tests: "./tests", // Test files
    cache: "./cache", // Cache directory
    artifacts: "./artifacts", // Build artifacts
  },
  external: {
    contracts: [
      {
        artifacts: "node_modules/@openzeppelin/contracts",
      },
    ],
  },
  allowPaths: ["../node_modules"], // Ensures dependencies in node_modules are resolved

  mocha: {
    timeout: 20000, // Test timeout in milliseconds
  },
};
