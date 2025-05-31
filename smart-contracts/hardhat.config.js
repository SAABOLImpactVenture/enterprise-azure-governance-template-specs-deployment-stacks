//require("@nomicfoundation/hardhat-toolbox");
//require("@typechain/hardhat");
//require("hardhat-gas-reporter");
//require("solidity-coverage");
//require("dotenv").config();

//module.exports = {
  //solidity: {
    //version: "0.8.20",
    //settings: {
      //optimizer: {
        //enabled: true,
        //runs: 200,
      //},
    //},
  //},
  //networks: {
    //hardhat: {},
    //goerli: {
      //url: process.env.GOERLI_RPC_URL || "",
      //accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    //},
    //sepolia: {
      //url: process.env.SEPOLIA_RPC_URL || "",
      //accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    //},
  //},
  //etherscan: {
    //apiKey: process.env.ETHERSCAN_API_KEY || "",
  //},
  //gasReporter: {
    //enabled: true,
    //currency: "USD",
    //coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    //outputFile: "gas-report.txt",
    //noColors: true,
  //},
  //typechain: {
    //outDir: "typechain",
    //target: "ethers-v5",
  //},
//};





require("@nomicfoundation/hardhat-toolbox");
require("@typechain/hardhat");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {},
    // Optional: Add testnets when you're ready
  },
  gasReporter: {
    enabled: false, // Turn off until you add API key
  },
};
