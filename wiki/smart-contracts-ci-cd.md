# 🧪 Smart Contracts CI/CD with Hardhat & GitHub Actions

This guide outlines the complete CI/CD process for **Solidity smart contracts** using **Hardhat**, **GitHub Actions**, and **Azure** for deployment environments. It is part of the broader architecture for **self-service landing zones** and integrates secure, automated testing and build workflows.

---

## 🧰 Tools & Frameworks

- [Hardhat](https://hardhat.org/)
- [Solidity](https://soliditylang.org/)
- [GitHub Actions](https://docs.github.com/actions)
- [VS Code](https://code.visualstudio.com/)
- Optional: [TypeChain](https://github.com/dethcrypto/TypeChain) and [Ethers.js](https://docs.ethers.io/)

---

## 📁 Folder Structure

smart-contracts/
├── contracts/
│ └── MyContract.sol
├── scripts/
│ └── deploy.js
├── test/
│ └── myContract.test.js
├── .env
├── hardhat.config.js
├── package.json
├── .github/
│ └── workflows/
│ └── hardhat-ci.yml


---

## ⚙️ Hardhat Initialization

```bash
mkdir smart-contracts
cd smart-contracts
npm init -y
npm install --save-dev hardhat
npx hardhat


#Shell
> Create a JavaScript project
> Root directory: ./smart-contracts
> Add sample project: Y

🧪 Running Tests
After adding tests to test/myContract.test.js, run:

npx hardhat compile
npx hardhat test

🔐 .env File (Example)
Create a .env file to securely store keys:

PRIVATE_KEY=your_wallet_private_key
INFURA_API_KEY=your_infura_key

Be sure to add .env to your .gitignore.

🛠 GitHub Actions CI/CD
Create the file: .github/workflows/hardhat-ci.yml

name: Hardhat CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npx hardhat test

🧠 Example: MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    uint public value;

    function setValue(uint _value) public {
        value = _value;
    }
}

🧪 Example Test
const { expect } = require("chai");

describe("MyContract", function () {
  it("should set the value correctly", async function () {
    const MyContract = await ethers.getContractFactory("MyContract");
    const contract = await MyContract.deploy();
    await contract.setValue(123);
    expect(await contract.value()).to.equal(123);
  });
});


🚀 Optional: Deployment Script
async function main() {
  const [deployer] = await ethers.getSigners();
  const MyContract = await ethers.getContractFactory("MyContract");
  const contract = await MyContract.deploy();
  console.log("Deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


Run with:

npx hardhat run scripts/deploy.js --network rinkeby
