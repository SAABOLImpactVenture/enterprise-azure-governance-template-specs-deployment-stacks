[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE.md)
![CI](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/actions/workflows/landing-zone-ci.yml/badge.svg)
![Deploy Blockchain Env](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/actions/workflows/deploy-blockchain-env.yml/badge.svg)
![Hardhat CI](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/actions/workflows/hardhat-ci.yml/badge.svg)

---

> **💡 Quick Overview**  
> This repo delivers a complete **Enterprise-Scale Azure Landing Zone** with built-in governance, a hardened **DevTest Lab** sandbox, an **IBFT-consensus Hyperledger Besu network** for integration testing, and **Full CI/CD** for Solidity contracts via GitHub Actions.

---

## 🚀 Quickstart

1. **Clone the repository**
    ```bash
    git clone https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks.git
    cd enterprise-azure-governance-template-specs-deployment-stacks
    ```

2. **Install prerequisites**
   - Azure CLI ≥ 2.40.0 & Bicep CLI
   - Node.js ≥ 16.x & npm

3. **Configure required parameters and secrets**
   - See [Configuration](#-configuration) and [sample .env](./smart-contracts/.env.example)
   - Set GitHub secrets: `SANDBOX_SUBSCRIPTION_ID`, `DEVTEST_LAB_RG`, etc.

4. **Deploy Landing Zone**
    ```bash
    az login
    az account set --subscription <your-infra-subscription>
    az deployment sub create \
      --location eastus \
      --template-file bicep/landing-zone.bicep \
      --parameters @bicep/parameters/landing-zone-parameters.json
    ```

5. **Provision DevTest Lab**
    ```bash
    az group create --name rg-sandbox-lab --location eastus
    az lab create \
      --resource-group rg-sandbox-lab \
      --name blockchain-devtestlab \
      --location eastus \
      --storage-type Premium
    ```

6. **Deploy Blockchain Environment and Smart Contracts**
    - Push to main triggers pipelines, or run:
    ```bash
    cd smart-contracts
    npm install
    npx hardhat compile
    npx hardhat test
    export BLOCKCHAIN_RPC="http://rpc-1.blockchain-devtestlab.lab.azure.com:8545"
    npx hardhat run scripts/deploy.js --network devtest
    ```

---

## 📖 Table of Contents

- [About](#-about)
- [Quickstart](#-quickstart)
- [Configuration](#-configuration)
- [Documentation & Wiki](#-documentation--wiki)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Product Vision & Roadmap](#-product-vision--roadmap)
- [CI/CD Pipelines](#-cicd-pipelines)
- [Contributing](#-contributing)
- [Troubleshooting & FAQ](#-troubleshooting--faq)
- [License & Support](#-license--support)

---

## 🎯 About

This repository combines:
- **Enterprise-Scale Landing Zone**: Azure Management Groups, Policies, RBAC, networking, monitoring.
- **DevTest Lab Sandbox**: Secure VMs, Just-In-Time (JIT) access, nightly auto-shutdown.
- **IBFT-Based Hyperledger Besu Network**: 4 validator nodes, 2 RPC/API nodes, 2 bootnodes for realistic integration testing.
- **Smart-Contract Framework**: Solidity contracts with OpenZeppelin, NatSpec, Mocha/Chai testing.
- **CI/CD**: GitHub Actions for Bicep deployments and smart-contract pipelines.

---

## ⚙️ Configuration

### Environment Variables & Secrets

- `.env` file in `smart-contracts/` (see [sample](./smart-contracts/.env.example)):
  ```
  PRIVATE_KEY=your_wallet_private_key
  GOERLI_URL=https://...
  MAINNET_URL=https://...
  ETHERSCAN_API_KEY=...
  ```
- [GitHub Secrets](https://docs.github.com/actions/security-guides/encrypted-secrets):
  - `SANDBOX_SUBSCRIPTION_ID`
  - `DEVTEST_LAB_RG`
  - OIDC or PAT for Azure login

### Parameter Files

- Bicep/ARM: see `bicep/parameters/landing-zone-parameters.json`
- Document all required parameters; recommend creating your own copy per environment.

---

## 📚 Documentation & Wiki

- [📚 Wiki Home](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki)
- [Playbook: End-to-End Automation](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/playbook.md)
- [Security: DevTest Lab Hardening](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/devtest-lab-security.md)
- [Monitoring & Diagnostics](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/diagnostic-monitoring.md)
- [Smart Contracts CI/CD](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/smart-contracts-ci-cd.md)
- [Troubleshooting & FAQ](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/troubleshooting.md)

---

## ✨ Key Features

| Domain             | Technology                       | Highlights                                                                                       |
|--------------------|----------------------------------|--------------------------------------------------------------------------------------------------|
| **Infra**          | Azure Bicep, CLI                 | Management Groups, Policies, NSGs, Hub-Spoke networking                                          |
| **Governance**     | Azure Policy, RBAC               | Enforce VM SKUs, tag compliance, resource locks                                                  |
| **DevTest**        | Azure DevTest Labs, Artifacts    | Secure VM formulas, `install-besu.sh`, JIT, auto-shutdown                                        |
| **Blockchain**     | Hyperledger Besu, IBFT Consensus | 4 validators, 2 RPC/API nodes, 2 bootnodes; custom `genesis.json`                                |
| **SmartContracts** | Hardhat, OpenZeppelin, Mocha     | Local & network tests, coverage reports, NatSpec documentation                                   |
| **CI/CD**          | GitHub Actions                   | Multi-stage workflows: landing-zone, DevTest-lab env, smart-contract pipeline                    |

---

## 🏗 Architecture

![Landing Zone & DevTest Lab Blockchain](diagrams/LandingZoneBlockchain.png)

> **Figure:** Enterprise-Scale Landing Zone feeding into a DevTest Lab that hosts an IBFT Hyperledger Besu network for contract integration tests.

---

## 🛣 Product Vision & Roadmap

**Vision:**  
Enable end-to-end, governed blockchain development on Azure—from infrastructure provisioning to contract deployment—using a repeatable IBFT Besu test network.

### Epics & Goals

| Epic                                      | Goal                                                                                                                       |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| **Enterprise Foundation**                 | Stand up Azure management groups, policies, subscriptions, and core services to enforce compliance and cost controls.      |
| **DevTest Lab Sandbox**                   | Provision an isolated sandbox subscription with DevTest Lab VMs, artifacts, JIT access, and auto-shutdown.                 |
| **Smart-Contract Framework**              | Build and harden Solidity contracts (access control, governance registry) with OpenZeppelin, tests, and docs.              |
| **CI/CD Automation**                      | Create GitHub Actions pipelines for infrastructure deployment and contract compile/test/deployment.                         |
| **Blockchain Sandbox Infra**              | Deploy/configure an IBFT-consensus Hyperledger Besu network for realistic integration tests.                               |
| **Contract Integration Testing**          | Integrate Hardhat CI against the live Besu network, automating end-to-end smart-contract tests (unit, integration, etc.)   |

---

## 🔄 CI/CD Pipelines

- **landing-zone-ci.yml** — Landing Zone infra deployment
- **deploy-blockchain-env.yml** — IBFT Besu environment deployment
- **hardhat-ci.yml** — Smart-contract compile/test/deploy

Pipelines run on push/PR to `main`. Status badges are at the top of this README.

---

## 🛡️ Security

- Hardened network perimeter (NSGs, IP whitelisting)
- Just-In-Time (JIT) VM access
- Diagnostics/logging to Log Analytics
- Secrets managed with Key Vault and GitHub Actions secrets

See [Security Guide](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/devtest-lab-security.md).

---

## 🧑‍💻 Contributing

We welcome contributions!  
Please see [CONTRIBUTING.md](./CONTRIBUTING.md) and our [Code of Conduct](./CODE_OF_CONDUCT.md).  
Open [issues](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/issues) or join [Discussions](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/discussions).

---

## 🛠 Troubleshooting & FAQ

- See [Troubleshooting Wiki](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/wiki/troubleshooting.md) for common issues.
- For support, open an issue or start a discussion.

---

## 📄 License & Support

This project is licensed under the [MIT License](LICENSE.md).

For additional assistance, open an [Issue](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/issues) or [Discussion](https://github.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/discussions).

---
