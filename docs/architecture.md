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

## 🧠 Future Considerations

- Add support for **deployment stacks**
- Use **Just-in-Time (JIT) access** for VMs
- Integrate **Azure Key Vault** for secrets
- Add **gas usage analytics** to CI/CD
- Enable **multi-network deployments** for Ethereum-compatible chains

