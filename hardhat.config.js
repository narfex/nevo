module.exports = {
  solidity: "0.8.21",
  paths: {
    sources: "./contracts", // Your contract folder
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  external: {
    contracts: [
      {
        artifacts: "./lib/v4-core/artifacts",
        sources: "./lib/v4-core/src",
      },
    ],
  },
};
