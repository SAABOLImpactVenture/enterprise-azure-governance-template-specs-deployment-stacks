# 🏗 Landing Zone Overview

## 🎯 Purpose

This page provides an overview of the **Landing Zone** implemented using **Bicep**, **PowerShell**, and **GitHub Actions**. It serves as a secure, scalable, and repeatable foundation for deploying workloads into Azure, aligned with **Enterprise-Scale Architecture** best practices and designed for use in **Cloud Center of Excellence (CCoE)** environments.

---

## 🧱 Components Deployed

| Component | Description |
|----------|-------------|
| `landing-zone.bicep` | Main deployment script for the entire environment |
| `landing-zone.parameters.json` | Parameter file for customizing deployment |
| `network.bicep` | Sets up VNet, subnet, and NSG |
| `nsg.bicep` | Defines detailed NSG rules |
| `diagnostic.bicep` | Enables Azure Monitor diagnostics |
| `jit-access.bicep` | Sets up Just-in-Time access for VMs |
| `policy.bicep` | Defines policy assignments |
| `roleAssignment.bicep` | Assigns RBAC roles programmatically |
| `devtest-vm.parameters.json` | Parameters specific to DevTest VM |

---

## 🛡 Security

- 🔒 **NSG Rules**: Enforced to restrict access to only required IPs and ports.
- 🔐 **JIT Access**: Enabled to reduce VM attack surface.
- 📊 **Diagnostics**: Logs sent to centralized Log Analytics workspace.

---

## 🧩 Integration

This landing zone integrates:
- 🧪 **DevTest Labs** for isolated test environments
- 🔁 **CI/CD workflows** for continuous deployment via GitHub Actions
- ⚙️ **GitHub Actions** using `landing-zone-ci.yml` for infrastructure provisioning
- 💬 **Smart Contract Development** folder for blockchain workload inclusion

---

## 📦 Folder Structure

/landing-zone
│
├── bicep/
│ ├── landing-zone.bicep
│ ├── network.bicep
│ ├── nsg.bicep
│ ├── diagnostic.bicep
│ ├── jit-access.bicep
│ ├── policy.bicep
│ └── roleAssignment.bicep
│
├── parameters/
│ ├── landing-zone.parameters.json
│ └── devtest-vm.parameters.json
│
├── scripts/
│ ├── enable-diagnostic.ps1
│ ├── enable-jit.ps1
│ └── configure-nsg.ps1
│
├── .github/workflows/
│ └── landing-zone-ci.yml


---

## 🚀 Deployment

To deploy:

```bash
az deployment sub create \
  --location eastus \
  --template-file ./bicep/landing-zone.bicep \
  --parameters ./parameters/landing-zone.parameters.json

#Or trigger the GitHub Actions pipeline to do it automatically on commit.