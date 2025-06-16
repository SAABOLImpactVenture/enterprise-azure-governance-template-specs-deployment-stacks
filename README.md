[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE.md)

---

> **💡 Quick Overview**  
> This repo delivers a complete **Enterprise-Scale Azure Landing Zone** with built-in governance, plus a hardened **DevTest Lab** sandbox that now includes an **IBFT-consensus Hyperledger Besu network** for integration testing, and **Full CI/CD** for Solidity contracts via GitHub Actions.

---

## 📖 Table of Contents

1. [About](#about)  
2. [Product Vision & Roadmap](#product-vision--roadmap)  
3. [Key Features](#key-features)  
4. [Architecture](#architecture)  
5. [Prerequisites](#prerequisites)  
6. [Getting Started](#getting-started)  
7. [Repo Layout](#repo-layout)  
8. [Deploy Landing Zone](#deploy-landing-zone)  
9. [Provision DevTest Lab](#provision-devtest-lab)  
   - 9.1 [Core DevTest Lab](#core-devtest-lab)  
   - 9.2 [Blockchain DevTest Lab Environment](#blockchain-devtest-lab-environment)  
10. [Smart-Contract Workflow](#smart-contract-workflow)  
11. [CI/CD Pipelines](#ci-cd-pipelines)  
12. [Contributing](#contributing)  
13. [License & Support](#license--support)  
14. [GitHub Wiki Structure](#github-wiki-structure)  

---

## 🎯 About

This repository combines:

- **Enterprise-Scale Landing Zone**: Azure Management Groups, Policies, RBAC, networking, monitoring.  
- **DevTest Lab Sandbox**: secure VMs, Just-In-Time access, nightly auto-shutdown.  
- **IBFT-Based Hyperledger Besu Network**: 4 validator nodes, 2 RPC/API nodes, 2 bootnodes (private & public) for realistic integration testing.  
- **Smart-Contract Framework**: Solidity contracts with OpenZeppelin, NatSpec, Mocha/Chai testing.  
- **CI/CD**: GitHub Actions for Bicep deployments and smart-contract pipelines.

---

## 🎯 Product Vision & Roadmap

**Vision:**  
Enable end-to-end, governed blockchain development on Azure—from infrastructure provisioning to contract deployment—using a repeatable IBFT Besu test network.

### Epics & Goals

| Epic                                      | Goal                                                                                                                       |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **EPIC 1: Enterprise Foundation**         | Stand up Azure management groups, policies, subscriptions, and core services to enforce compliance and cost controls.      |
| **EPIC 2: DevTest Lab Sandbox**           | Provision an isolated sandbox subscription with DevTest Lab VMs, artifacts, JIT access, and auto-shutdown.                 |
| **EPIC 3: Smart-Contract Framework**      | Build and harden Solidity contracts (access control, governance registry) with OpenZeppelin, tests, and docs.              |
| **EPIC 4: CI/CD Automation**              | Create GitHub Actions pipelines for infrastructure deployment and contract compilation/testing/deployment.                 |
| **EPIC 5: Blockchain Sandbox Infra**      | Deploy and configure an IBFT-consensus Hyperledger Besu network in DevTest Lab—including 4 validators, 2 RPC/API nodes, and 2 bootnodes—for realistic integration tests. |
| **EPIC 6: Contract Integration Testing**  | Integrate Hardhat CI against the live Besu network, automating end-to-end smart-contract tests (unit, integration, governance flows). |

---

## ✨ Key Features

| Domain             | Technology                       | Highlights                                                                                       |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Infra**          | Azure Bicep, CLI                 | Management Groups, Policies, NSGs, Hub-Spoke networking                                          |
| **Governance**     | Azure Policy, RBAC               | Enforce VM SKUs, tag compliance, resource locks                                                  |
| **DevTest**        | Azure DevTest Labs, Artifacts    | Secure VM formulas, `install-besu.sh`, JIT, auto-shutdown                                        |
| **Blockchain**     | Hyperledger Besu, IBFT Consensus | 4 validators, 2 RPC/API nodes, 2 bootnodes; custom `genesis.json` (Chain ID, Difficulty, GasLimit, Alloc, IBFT config) |
| **SmartContracts** | Hardhat, OpenZeppelin, Mocha     | Local & network tests, coverage reports, NatSpec documentation                                   |
| **CI/CD**          | GitHub Actions                   | Multi-stage workflows: landing-zone, DevTest-lab env, smart-contract pipeline                     |

---

## 🏗 Architecture

![Landing Zone & DevTest Lab Blockchain](diagrams/LandingZoneBlockchain.png)

> **Figure:** Enterprise-Scale Landing Zone feeding into a DevTest Lab that hosts an IBFT Hyperledger Besu network for contract integration tests.

---

## 🔧 Prerequisites

- Azure subscription with permissions to create Management Groups, Subscriptions, DevTest Labs  
- Azure CLI ≥ 2.40.0 & Bicep CLI  
- Node.js ≥ 16.x & npm  
- GitHub OIDC / PAT setup for Azure login  
- `SANDBOX_SUBSCRIPTION_ID` & `DEVTEST_LAB_RG` set as GitHub Secrets  

---

## 🚀 Getting Started

<details>
<summary>1. Clone Repository</summary>

```bash
git clone https://github.com/YourOrg/YourRepo.git
cd YourRepo


<details>
<summary>2. Azure Login & Subscription</summary>

```bash
az login
az account set --subscription <your-infra-subscription>

⚙️ Deploy Landing Zone
az deployment sub create \
  --location eastus \
  --template-file bicep/landing-zone.bicep \
  --parameters @bicep/parameters/landing-zone-parameters.json

🖥 Provision DevTest Lab

9.1 Core DevTest Lab

az group create --name rg-sandbox-lab --location eastus

az lab create \
  --resource-group rg-sandbox-lab \
  --name blockchain-devtestlab \
  --location eastus \
  --storage-type Premium

az lab formula create-quota \
  --lab-name blockchain-devtestlab \
  --resource-group rg-sandbox-lab \
  --user-entitlement quotaType=Core count=8


9.2 Blockchain DevTest Lab Environment
Upload install-besu.sh artifact

az lab artifact create \
  --resource-group rg-sandbox-lab \
  --lab-name blockchain-devtestlab \
  --name install-besu \
  --display-name "IBFT Besu Installer" \
  --artifact-type CustomScript \
  --uri "https://raw.githubusercontent.com/YourOrg/YourRepo/main/devtest-lab/scripts/install-besu.sh" \
  --parameters '{
    "GENESIS_URI":{"type":"string","defaultValue":""},
    "CHAIN_ID":{"type":"string","defaultValue":"10"},
    "GAS_LIMIT":{"type":"string","defaultValue":"0x1C9C380"},
    "BOOTNODES":{"type":"string","defaultValue":""},
    "RPC_ENABLED":{"type":"boolean","defaultValue":false}
  }'


Configure devtest-lab/parameters/blockchain-env.parameters.json

{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "labName":      { "value": "blockchain-devtestlab" },
    "labRg":        { "value": "rg-sandbox-lab" },
    "location":     { "value": "eastus" },
    "hubVnetId":    { "value": "/subscriptions/.../resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/hub-vnet" },
    "keyVaultName": { "value": "dev-blockchain-kv-eastus" }
  }
}


Push your devtest-lab/ changes to trigger .github/workflows/deploy-blockchain-env.yml and verify that 4 validator, 2 RPC/API, and 2 bootnode VMs (running Hyperledger Besu IBFT) come online.

📜 Smart-Contract Workflow
Local dev

cd smart-contracts
npm install
npx hardhat compile
npx hardhat test

Integration tests against Besu
export BLOCKCHAIN_RPC="http://rpc-1.blockchain-devtestlab.lab.azure.com:8545"
npx hardhat test --network devtest


Deploy contracts into lab

npx hardhat run scripts/deploy.js --network devtest

🔄 CI/CD Pipelines
landing-zone-ci.yml — Landing Zone infra

deploy-blockchain-env.yml — IBFT Besu environment

hardhat-ci.yml — Smart-contract compile/test/deploy


