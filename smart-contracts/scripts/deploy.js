// deploy.js - Script for deploying smart contracts 
// Path: smart-contracts/scripts/deploy.js

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

async function main() {
  console.log("Starting deployment process...");
  
  // Get network information
  const network = hre.network.name;
  console.log(`Deploying to ${network} network`);
  
  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying with account: ${deployer.address}`);
  
  // Check deployer balance
  const deployerBalance = await deployer.getBalance();
  console.log(`Deployer balance: ${ethers.utils.formatEther(deployerBalance)} ETH`);
  
  try {
    // Deploy GovernanceRegistry contract
    console.log("Deploying GovernanceRegistry contract...");
    const GovernanceRegistry = await ethers.getContractFactory("GovernanceRegistry");
    const governanceRegistry = await GovernanceRegistry.deploy();
    await governanceRegistry.deployed();
    console.log(`GovernanceRegistry deployed to: ${governanceRegistry.address}`);
    
    // Deploy AccessControl contract
    console.log("Deploying AccessControl contract...");
    const AccessControl = await ethers.getContractFactory("AccessControl");
    const accessControl = await AccessControl.deploy(governanceRegistry.address);
    await accessControl.deployed();
    console.log(`AccessControl deployed to: ${accessControl.address}`);
    
    // Save deployment info
    const deploymentInfo = {
      network,
      deployer: deployer.address,
      governanceRegistry: governanceRegistry.address,
      accessControl: accessControl.address,
      timestamp: new Date().toISOString(),
    };
    
    // Create deployment directory if it doesn't exist
    const deploymentDir = path.join(__dirname, "../deployments", network);
    if (!fs.existsSync(deploymentDir)) {
      fs.mkdirSync(deploymentDir, { recursive: true });
    }
    
    // Write deployment info to file
    fs.writeFileSync(
      path.join(deploymentDir, "deployment.json"),
      JSON.stringify(deploymentInfo, null, 2)
    );
    console.log(`Deployment info saved to ${path.join(deploymentDir, "deployment.json")}`);
    
    // Verify contracts on Etherscan if not on local network
    if (network !== "localhost" && network !== "hardhat") {
      console.log("Waiting for block confirmations...");
      // Wait for 5 block confirmations
      await governanceRegistry.deployTransaction.wait(5);
      await accessControl.deployTransaction.wait(5);
      
      console.log("Verifying contracts on Etherscan...");
      try {
        await hre.run("verify:verify", {
          address: governanceRegistry.address,
          constructorArguments: [],
        });
        
        await hre.run("verify:verify", {
          address: accessControl.address,
          constructorArguments: [governanceRegistry.address],
        });
        
        console.log("Contract verification complete");
      } catch (error) {
        console.log("Error verifying contracts:", error.message);
      }
    }
    
    console.log("Deployment completed successfully!");
    return deploymentInfo;
    
  } catch (error) {
    console.error("Error during deployment:", error);
    process.exit(1);
  }
}

// Execute deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });