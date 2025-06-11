 [![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE.md)

---



---

> **💡 Quick Overview**
> This repo delivers an **Enterprise-Scale Azure Landing Zone** with built-in governance, plus a **DevTest Lab** setup for secure VM-based smart contract development and **Full CI/CD** for Solidity contracts via GitHub Actions.

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
10. [Smart Contract Workflow](#smart-contract-workflow)
11. [CI/CD Pipelines](#ci-cd-pipelines)
12. [Contributing](#contributing)
13. [License & Support](#license--support)
14. [GitHub Wiki Structure](#github-wiki-structure)

---

## 🎯 About

A turnkey foundation combining Azure best practices with a hardened DevTest Lab environment, plus a developer-friendly pipeline for writing, testing, and deploying Solidity contracts.

---

## 🎯 Product Vision & Roadmap

**Vision:**
Enable secure, governed blockchain development on Azure—providing teams with an enterprise-grade landing zone, a hardened DevTest Lab sandbox, and a streamlined CI/CD pipeline for Solidity contracts—so that developers can move from “code” to “chain” with confidence and compliance.

### Epics & Goals

| Epic                                 | Goal                                                                                                                  |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| **EPIC 1: Enterprise Foundation**    | Stand up Azure management groups, policies, subscriptions, and core services to enforce compliance and cost controls. |
| **EPIC 2: DevTest Lab Sandbox**      | Provision an isolated sandbox subscription with DevTest Lab VMs, artifacts, JIT access, and auto-shutdown.            |
| **EPIC 3: Smart-Contract Framework** | Build and harden Solidity contracts (access control, governance registry) with OpenZeppelin, tests, and docs.         |
| **EPIC 4: CI/CD Automation**         | Create GitHub Actions pipelines for infrastructure deployment and contract compilation/testing/deployment.            |

### Key Features & User Stories

* **Feature 1.1: Management Group Hierarchy**

  * *As a cloud architect, I want a clear Management-Group → Subscription design so that environments (Prod, Sandbox, Dev) inherit policies automatically.*

* **Feature 1.2: Azure Policy & RBAC Baselines**

  * *As a security lead, I need guardrails (policy assignments, resource locks) so engineers can’t spin up non-compliant resources.*

* **Feature 2.1: DevTest Lab VM Templates**

  * *As a blockchain developer, I want a pre-configured VM template (Node.js, Hardhat, Azure CLI) so I can start coding immediately.*

* **Feature 2.2: Just-In-Time Access & Auto-Shutdown**

  * *As an ops engineer, I need JIT RDP/SSH and nightly auto-shutdown so we minimize attack surface and costs.*

* **Feature 3.1: Role-Based Access Control Contract**

  * *As a governance admin, I want to grant/revoke roles on-chain so I can manage permissions dynamically.*

* **Feature 3.2: Governance Registry Contract**

  * *As a protocol owner, I want to store key-value parameters on-chain with event logs so downstream services can react to changes.*

* **Feature 3.3: OpenZeppelin Integration & NatSpec**

  * *As a developer, I want standardized, audited libraries and inline docs so my contracts are secure and self-documenting.*

* **Feature 4.1: Infra Pipeline**

  * *As an SRE, I want a pipeline that validates and deploys Bicep modules to Dev, Sandbox, and Prod so infrastructure is versioned and reproducible.*

* **Feature 4.2: Smart-Contract Pipeline**

  * *As a blockchain developer, I want a pipeline that compiles, tests, measures coverage, and (optionally) deploys my contracts so every commit is verified.*

### High-Level Roadmap

| Sprint       | Objectives                                                       | Deliverables                                                |
| ------------ | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| **Sprint 0** | Prep & Planning: finalize backlog, branch strategy, environments | Product brief, backlog in GH Issues, feature branch created |
| **Sprint 1** | Complete EPIC 1: Foundation core                                 | Management Groups + Policies deployed, docs updated         |
| **Sprint 2** | Kick off EPIC 2: DevTest Lab sandbox                             | DevTest Lab subscription + VM templates live                |
| **Sprint 3** | Begin EPIC 3: Contract scaffolding                               | AccessControl & GovernanceRegistry stubs merged             |
| **Sprint 4** | Continue EPIC 3 & add tests, NatSpec                             | Contracts fully implemented, test suite passing             |
| **Sprint 5** | Launch EPIC 4 pipelines                                          | GH Actions workflows green end-to-end                       |
| **Sprint 6** | Polish, docs, and hand-off                                       | Wiki complete, DevTest lab live, ready for dev              |

**Next Actions:**

1. Finalize backlog & branch: create `feature/migrate-openzeppelin` and log Issues.
2. Kick off Smart-Contract Epics: start AccessControl migration and test development.
3. Document Progress: update Wiki under **Smart Contracts CI/CD** with NatSpec and testing instructions.

---

## ✨ Key Features

|         Domain | Technology                      | Highlights                                  |
| -------------: | ------------------------------- | ------------------------------------------- |
|      **Infra** | Bicep, Azure CLI                | Modular templates, **RBAC**, NSGs, JIT      |
| **Governance** | Azure Policy, Management Groups | Security baselines, cost controls           |
|    **DevTest** | DevTest Labs, ARM/Bicep         | Secure VMs, artifacts, auto-shutdown        |
| **Blockchain** | Hardhat, Mocha/Chai             | Local testing, coverage reports             |
|      **CI/CD** | GitHub Actions                  | Multi-stage pipelines for infra & contracts |

---

## 🏗 Architecture

![Landing Zone & CI/CD Workflow](diagrams/LandingZoneArchitecture.png)

> A high-level workflow showing how Bicep modules, DevTest Lab, and GitHub Actions integrate for end-to-end automation.

---

## 🔧 Prerequisites

* **Azure Subscription** (Owner)
* **Azure CLI** ≥ 2.40.0
* **Bicep CLI**
* **Node.js** ≥ 16.x & **npm**
* **GitHub PAT** with `repo` & `workflow` scopes

---

## 🚀 Getting Started

<details>
<summary>1. Clone Repository</summary>

```bash
git clone https://github.com/YourOrg/YourRepo.git
cd YourRepo
```

</details>

<details>
<summary>2. Azure Login & Subscription</summary>

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

</details>

<details>
<summary>3. Deploy Landing Zone</summary>

```bash
az deployment sub create \
  --location eastus \
  --template-file bicep/landing-zone.bicep \
  --parameters @bicep/parameters/landing-zone-parameters.json
```

</details>

<details>
<summary>4. Provision DevTest Lab VM</summary>

```bash
az deployment group create \
  --resource-group DevTestLabRG \
  --template-file devtest-lab/devtest-lab.bicep \
  --parameters @devtest-lab/parameters/devtest-vm.parameters.json
```

</details>

<details>
<summary>5. Smart Contract Dev & Test</summary>

```bash
cd smart-contracts
npm install
npx hardhat compile
npx hardhat test
```

</details>

<details>
<summary>6. Manual Deploy Contracts</summary>

```bash
npx hardhat run scripts/deploy.js --network <network>
```

</details>

---

## 📂 Repo Layout

```text
├── .github/workflows/      # GitHub Actions
├── bicep/                  # Landing Zone modules
├── devtest-lab/            # DevTest Lab templates & scripts
├── smart-contracts/        # Solidity, tests, configs
├── docs/                   # Additional guides
├── diagrams/               # Visio/PNG architecture diagrams
├── scripts/                # Automation & helper scripts
├── wiki/                   # Markdown stubs for GitHub Wiki
├── LICENSE.md
└── README.md
```

---

## ⚙️ Deploy Landing Zone

Deep dive into Bicep modules, parameterization, and security controls in \[wiki/landing-zone-overview\.md].

---

## 🖥 Provision DevTest Lab

Secure VM provisioning, artifact management, and auto-shutdown strategies in \[wiki/devtest-lab-security.md].

---

## 📜 Smart Contract Workflow

Hardhat setup, test strategy, and deployment steps documented in \[wiki/smart-contracts-ci-cd.md].

---

## 🔄 CI/CD Pipelines

Multi-stage GitHub Actions: infra (landing-zone-ci.yml) & blockchain (hardhat-ci.yml). Full docs in \[wiki/ci-cd-overview\.md].

---

## 🤝 Contributing

We love contributions! Please ensure you:

1. Fork the repo
2. Follow **conventional commits**
3. Run & pass existing tests
4. Submit a PR with clear description

See \[CODE\_OF\_CONDUCT.md] for guidelines.

---

## 📜 License & Support

Licensed under MIT. Open an issue or contact @YourGitHubHandle for help.

---

# 📚 GitHub Wiki Structure

Below are the primary wiki pages; each has an intro stub in `/wiki`:

* **Home** (`Home.md`)
* **Landing Zone Overview** (`landing-zone-overview.md`)
* **Programmatic Deployment** (`programmatic-deployment.md`)
* **DevTest Lab Security** (`devtest-lab-security.md`)
* **Smart Contracts CI/CD** (`smart-contracts-ci-cd.md`)
* **CI/CD Overview** (`ci-cd-overview.md`)
* **Troubleshooting** (`troubleshooting.md`)
* **FAQ** (`faq.md`)

