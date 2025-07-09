# Architecture Overview

This repository supports a modular and enterprise-aligned approach for deploying cloud environments and smart contracts using Azure, Bicep, GitHub Actions, and Solidity.



## 🏗️ Landing Zone Architecture

The landing zone deployment aligns with Microsoft's Enterprise-Scale reference architecture and includes:

- Management Group hierarchy
- Policy definitions and assignments
- Role-based access control (RBAC)
- Resource group scaffolding
- Networking baselines (vNETs, subnets, NSGs)

### Technologies Used

- **Azure Bicep**
- **Azure Policy**
- **Azure Role Assignments**
- **Template Specs** *(Blueprint replacement)*
- **GitHub Actions for CI/CD*



## ⚖️ Smart Contracts Platform Architecture

The smart contract portion is built using:

- **Solidity** for writing contracts
- **Hardhat** for development, testing, and deployment
- **GitHub Actions** for CI workflows
- **Ethers.js** for interacting with the Ethereum network

### Folder Structure

smart-contracts/
│
├── contracts/ # Solidity contracts
├── scripts/ # Deployment scripts
├── test/ # Hardhat tests
├── .env # Environment variables (local)
├── hardhat.config.js # Hardhat configuration
└── package.json # NPM config & dependencies


## 🔁 Integration Points

| Component                | Purpose                          |
|-------------------------|----------------------------------|
| GitHub Actions          | CI/CD pipelines                  |
| Azure DevTest Labs      | Sandbox compute for smart contract development |
| Azure Monitor + NSGs    | Security and observability       |
| Template Specs (Bicep)  | Infrastructure as Code           |

---

# Summary 

This summary focuses on the infrastructure, blockchain, and smart contract components described in `architecture.md`.

---

## Infrastructure (Landing Zone Architecture)

- The repo enables a modular, enterprise-ready Azure cloud setup using Infrastructure-as-Code and automation.

**Key components:**
- Management Group hierarchy for governance.
- Azure Policy for compliance and enforcement.
- Role-Based Access Control (RBAC) for security.
- Resource group scaffolding for organizing resources.
- Networking baselines: virtual networks (vNETs), subnets, and network security groups (NSGs).

**Technologies:**
- Azure Bicep for infrastructure definitions.
- Template Specs as a replacement for Blueprints.
- GitHub Actions for CI/CD automation.

---

## Blockchain & Smart Contracts

- The smart contract stack is built around Ethereum and Solidity.

**Core elements:**
- Solidity for contract development.
- Hardhat for developing, testing, and deploying contracts.
- Ethers.js for blockchain interaction.
- GitHub Actions for CI/CD.

**Directory structure:**
- `contracts/`: Solidity source files.
- `scripts/`: Deployment automation.
- `test/`: Hardhat tests.
- `hardhat.config.js`: Project configuration.

---

## Integration Points

- GitHub Actions: Automates build, test, and deployment for both infra and smart contracts.
- Azure DevTest Labs: Provides sandbox environments for development.
- Azure Monitor + NSGs: For security and monitoring.
- Template Specs (Bicep): Infrastructure as Code for repeatable deployments.

---

## Future Considerations (Planned Enhancements)

- Support for deployment stacks.
- Just-in-Time access for improved VM security.
- Azure Key Vault integration for secrets management.
- Gas usage analytics in CI/CD.
- Multi-network Ethereum deployment support.

---



