# 🔐 DevTest Lab Security Guide

This document outlines security practices applied to the Azure DevTest Lab environment to protect resources and minimize attack surfaces. It includes network controls, diagnostic logging, and Just-in-Time (JIT) access.

---

## 📍 1. Network Security Group (NSG) Rules

### ✅ Applied Rules
- **Allow SSH (port 22)**: Limited to trusted IP ranges only (e.g., your public IP).
- **Allow RDP (port 3389)**: Only if Windows VMs are used, again limited to known IPs.
- **Deny All Inbound**: Default rule to block all other traffic.

### 🔧 Configuration Tools
- `nsg.bicep`: Defines the NSG and rules.
- `configure-nsg.ps1`: PowerShell script to apply IP restrictions dynamically.

---

## 🛡️ 2. Just-in-Time (JIT) VM Access

### 🎯 Purpose
Reduce exposure of SSH/RDP ports by allowing access only when requested and approved through Azure Security Center.

### ⚙️ Tooling
- **Bicep Module**: `jit-access.bicep` enables JIT configuration.
- **PowerShell Script**: `enable-jit.ps1` registers VMs for JIT in Security Center.

---

## 📊 3. Diagnostics and Monitoring

### 🔍 Enable Resource Monitoring
- Logs VM performance, security events, and metrics into Log Analytics Workspace.

### 🛠️ Configuration
- **Bicep**: `diagnostic.bicep` configures diagnostic settings.
- **Script**: `enable-diagnostic.ps1` automates setup for diagnostics on VM resources.

---

## 🧱 4. Integration into CI/CD

Security provisioning is integrated in the CI pipeline:
- **`landing-zone-ci.yml`**: Deploys infrastructure and enforces NSG, diagnostics, and JIT access policies.

---

## 📌 Best Practices

- Restrict inbound ports using IP whitelisting.
- Always enable diagnostic logging for VMs and network interfaces.
- Use JIT access for VMs that require occasional admin login.
- Routinely review NSG rules and logs in Log Analytics.
- Integrate security controls into Infrastructure as Code (IaC).

---

## 📚 Related Files

| File                         | Description                              |
|------------------------------|------------------------------------------|
| `nsg.bicep`                  | NSG resource definition with rules       |
| `jit-access.bicep`           | Enables JIT for DevTest VMs              |
| `diagnostic.bicep`           | Sets up diagnostics for VMs              |
| `configure-nsg.ps1`          | Applies IP restrictions to NSG           |
| `enable-jit.ps1`             | Enables JIT VM access                    |
| `enable-diagnostic.ps1`      | Sets diagnostic settings on VMs          |

---
