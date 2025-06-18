// scripts/genValidatorAccounts.js
const { Wallet } = require("ethers");
const fs = require("fs");
const path = require("path");

const outputDir = path.join(__dirname, "../devtest-lab/genesis/keys");
fs.mkdirSync(outputDir, { recursive: true });

const accounts = [];
for (let i = 1; i <= 4; i++) {
  const w = Wallet.createRandom();
  accounts.push({ validator:`validator-${i}`, address: w.address });
  fs.writeFileSync(path.join(outputDir, `validator-${i}.key`), w.privateKey);
}

fs.writeFileSync(
  path.join(outputDir, "validatorAccounts.json"),
  JSON.stringify(accounts, null, 2)
);

console.log("✅ Generated 4 validator keypairs in:", outputDir);
