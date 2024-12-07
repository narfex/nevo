// SPDX-License-Identifier: MIT
const ArbitrationHook = artifacts.require("ArbitrationHook");
const FiatFactoryHook = artifacts.require("FiatFactoryHook");
const OracleHook = artifacts.require("OracleHook");
const P2PFactoryHook = artifacts.require("P2PFactoryHook");
const ExchangeRouterHook = artifacts.require("ExchangeRouterHook");
const FiatToken = artifacts.require("FiatToken");
const NarfexExchangerPool = artifacts.require("NarfexExchangerPool");

module.exports = async function (deployer, network, accounts) {
  console.log("Deploying contracts...");

  // Deploy ArbitrationHook
  await deployer.deploy(ArbitrationHook);
  const arbitrationHook = await ArbitrationHook.deployed();
  console.log("ArbitrationHook deployed at:", arbitrationHook.address);

  // Deploy FiatFactoryHook
  await deployer.deploy(FiatFactoryHook);
  const fiatFactoryHook = await FiatFactoryHook.deployed();
  console.log("FiatFactoryHook deployed at:", fiatFactoryHook.address);

  // Deploy OracleHook
  await deployer.deploy(OracleHook);
  const oracleHook = await OracleHook.deployed();
  console.log("OracleHook deployed at:", oracleHook.address);

  // Deploy P2PFactoryHook
  await deployer.deploy(P2PFactoryHook);
  const p2pFactoryHook = await P2PFactoryHook.deployed();
  console.log("P2PFactoryHook deployed at:", p2pFactoryHook.address);

  // Deploy ExchangeRouterHook
  await deployer.deploy(ExchangeRouterHook);
  const exchangeRouterHook = await ExchangeRouterHook.deployed();
  console.log("ExchangeRouterHook deployed at:", exchangeRouterHook.address);

  // Deploy FiatToken
  await deployer.deploy(FiatToken, "USD Token", "USD");
  const fiatToken = await FiatToken.deployed();
  console.log("FiatToken deployed at:", fiatToken.address);

  // Deploy NarfexExchangerPool
  await deployer.deploy(
    NarfexExchangerPool,
    fiatToken.address,
    accounts[0], // Replace with appropriate router address
    accounts[0], // Replace with appropriate NRFX address
    accounts[0]  // Replace with appropriate MasterChef address
  );
  const narfexExchangerPool = await NarfexExchangerPool.deployed();
  console.log("NarfexExchangerPool deployed at:", narfexExchangerPool.address);
};
