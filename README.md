# Enterprise-Scale Landing Zone + Smart Contract CI/CD (Azure + GitHub)

This project demonstrates a modern cloud-native architecture that integrates **Azure Enterprise-Scale Infrastructure-as-Code** with a **Smart Contract CI/CD pipeline using Hardhat**, fully managed through **Visual Studio Code and GitHub**.

## 🚀 Overview

- **Enterprise-Scale Bicep Templates** for Azure landing zones
- **Smart Contracts** built with Solidity + Hardhat
- **CI/CD Workflows** using GitHub Actions for both infrastructure and blockchain
- **Secure VM Provisioning** via Azure DevTest Labs
- **Network Hardening** with NSGs, Diagnostics, and Just-In-Time (JIT) Access
- **Documentation and Wiki** for step-by-step guidance


## 🧱 Tech Stack

- **Azure Bicep**
- **GitHub Actions**
- **Azure DevTest Labs**
- **NSG + Diagnostics + JIT**
- **Solidity + Hardhat**
- **Visual Studio Code**

## 📚 Getting Started

1. Clone the repository  
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git


This repository delivers a complete, extensible, and enterprise-grade Azure environment using:

- **Bicep** for Infrastructure-as-Code (IaC)
- **Template Specs** and **Deployment Stacks** as the successor to Azure Blueprints
- **DevTest Lab** setup with hardened NSGs, Just-in-Time (JIT) access, and diagnostics
- **Solidity + Hardhat** based Smart Contract CI/CD pipeline
- **GitHub Codespaces** for seamless development in-browser

> ⚠️ _The `parameters/` directory is excluded to encourage cloning this repo and supplying your own environment-specific configurations._

---

## 📦 Features

- **Modular Azure Landing Zone**: Deploy a secure, production-ready foundation across VNet, NSG, JIT, diagnostics, policy, and RBAC modules.
- **Smart Contract CI/CD**: Build and test Solidity contracts using Hardhat and GitHub Actions.
- **GitHub Codespaces Ready**: Jump straight into development without setup.
- **Cloud-Native Automation**: Use GitHub Actions, Azure CLI, and PowerShell scripts for hands-free deployment and security hardening.

---

## 📁 Repository Structure

| Path                          | Description |
|-------------------------------|-------------|
| `.github/workflows/`         | CI/CD pipelines for infrastructure and smart contracts |
| `bicep/`                      | Core Bicep modules (network, NSG, policy, JIT, diagnostics, etc.) |
| `powershell/`                | Automation scripts for NSG, diagnostics, and JIT |
| `smart-contracts/`           | Solidity smart contract project with Hardhat, tests, and configs |
| `wiki/`                       | Markdown files for GitHub Wiki docs |
| `images/`                     | Architecture and CI pipeline diagrams |
| `.devcontainer/`             | GitHub Codespaces container definition |
| `.gitignore` & `LICENSE.md` | Project metadata |

> ❌ `parameters/` is **not** included. You are expected to clone this repo and supply your own `parameters/landing-zone-parameters.json` and `devtest-vm.parameters.json`.

---

## 🚀 Getting Started with GitHub Codespaces

This repository is Codespaces-ready! To use:

1. Click the **Code** dropdown in GitHub
2. Select **Open with Codespaces**
3. GitHub provisions a preconfigured dev container with all required tools installed:
   - Node.js
   - Hardhat
   - Bicep CLI
   - Azure CLI

---

## 🔁 Use Cases

- ✅ **Enterprise Landing Zone** with Azure-native governance
- ✅ **DevTest Lab Setup** for secure development and testing
- ✅ **Blockchain Prototype** with Smart Contract CI/CD
- ✅ **Educational Tool** for learning Bicep, Template Specs, and secure DevOps

---

## 🛡️ Security Hardening

This repo supports:

- 🔐 NSG Rules with restricted access
- 🕒 Just-in-Time (JIT) access via Azure Security Center
- 📊 VM diagnostics integration with Log Analytics
- 🎯 Role-based access control (RBAC) via Bicep

---

## 🧪 Smart Contract CI/CD Pipeline

- ✅ Written in **Solidity**
- ✅ Tested with **Mocha** via **Hardhat**
- ✅ Automated with **GitHub Actions**
- ✅ Configurable `.env` for deployment credentials

---

## 📄 License

This project is licensed under the terms of the [MIT License](./LICENSE.md). You are free to fork, modify, and adapt this repo for your own use.

---

## 💡 Contribute

Contributions are welcome to improve or extend this project. Please fork the repository and submit a pull request.

---

## 🔗 Learn More

Refer to the `wiki/` directory or GitHub Wiki for deep dives into:
- [Landing Zone Architecture](wiki/landing-zone-overview.md)
- [Programmatic Deployment](wiki/programmatic-deployment.md)
- [DevTest Lab Security](wiki/devtest-lab-security.md)
- [Smart Contract CI/CD](wiki/smart-contracts-ci-cd.md)

