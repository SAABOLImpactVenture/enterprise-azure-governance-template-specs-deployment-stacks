// Smart Contract Deployment Script
const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("Starting deployment of smart contracts...");
  
  try {
    // Get the contract factory
    const GovernanceRegistry = await ethers.getContractFactory("GovernanceRegistry");
    
    // Deploy the contract
    console.log("Deploying GovernanceRegistry...");
    const governanceRegistry = await GovernanceRegistry.deploy();
    
    // Wait for deployment to complete
    await governanceRegistry.waitForDeployment();
    
    // Get the deployed contract address
    const deployedAddress = await governanceRegistry.getAddress();
    console.log(`GovernanceRegistry deployed to: ${deployedAddress}`);
    
    // Sample transaction to initialize the registry
    console.log("Initializing registry...");
    const tx = await governanceRegistry.initialize(
      process.env.ADMIN_ADDRESS || "0x1234567890123456789012345678901234567890"
    );
    await tx.wait();
    
    console.log("Deployment and initialization completed successfully!");
    return 0; // Success exit code
  } catch (error) {
    console.error("Error during deployment:", error);
    
    // Add more detailed error logging
    if (error.code === "CALL_EXCEPTION") {
      console.error("Contract call failed. Check your contract initialization parameters.");
    } else if (error.message.includes("insufficient funds")) {
      console.error("Insufficient funds for gas * price + value. Make sure your account has ETH.");
    }
    
    return 1; // Error exit code
  }
}

// Run the deployment
main()
  .then((exitCode) => process.exit(exitCode))
  .catch((error) => {
    console.error("Unhandled error:", error);
    process.exit(1);
  });