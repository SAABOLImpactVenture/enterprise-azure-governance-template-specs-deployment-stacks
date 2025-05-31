// scripts/deploy.js

const hre = require("hardhat");

async function main() {
  // Compile contracts if not already compiled
  await hre.run("compile");

  // Deploy the contract
  const MyContract = await hre.ethers.getContractFactory("MyContract");
  const myContract = await MyContract.deploy();

  await myContract.deployed();

  console.log(`MyContract deployed to: ${myContract.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
