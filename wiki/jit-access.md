# 🛡 Just-In-Time (JIT) Access for Azure Virtual Machines

## 📌 Overview

Just-In-Time (JIT) access reduces your attack surface by **limiting the time** when a VM is exposed to the public internet. With JIT enabled, you only allow access to your VMs **for a specific time** and from **specific IP addresses**, minimizing risk and improving operational security.

This page outlines how to enable and manage JIT access using **Azure Security Center**, **PowerShell**, and **Azure CLI**.

---

## ✅ Benefits of JIT Access

- 🔒 Reduces permanent exposure of ports like SSH (22) or RDP (3389)
- 🧾 Tracks access requests with audit logs
- 🕓 Allows access only when needed
- 🌐 Restricts access to defined IPs

---

## ⚙️ Enabling JIT via Azure Portal

1. Navigate to **Microsoft Defender for Cloud** > **Workload protections**
2. Under **Advanced protection**, go to **Just-in-time VM access**
3. Select your VM (e.g., `demosmartcontract-vm`)
4. Click **Enable JIT on VMs**
5. Set rules (IP range, allowed time window, allowed ports like 22 or 3389)
6. Save and apply

---

## 💻 PowerShell Script

```powershell
# enable-jit.ps1

$resourceGroup = "Dev_Test_Lab-demosmartcontract-vm-017910"
$vmName = "demosmartcontract-vm"

# Configure JIT policy using Microsoft Defender API
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/Microsoft.Security/locations/eastus/jitNetworkAccessPolicies/default?api-version=2020-01-01" \
  --body @"jit-policy.json"

#Make sure jit-policy.json contains the right port and IP configuration for the VM.

#CLI Example (Preview Feature)
az security jit-policy create \
  --location eastus \
  --name demosmartcontract-vm-jit \
  --resource-group Dev_Test_Lab-demosmartcontract-vm-017910 \
  --vm "demosmartcontract-vm" \
  --ports 22 3389 \
  --allowed-source-address-prefixes "<YOUR_IP>" \
  --max-request-access-duration PT1H

#Replace <YOUR_IP> with your trusted public IP address.

#📁 Related Files in Repo
| File               | Purpose                                   |
| ------------------ | ----------------------------------------- |
| `enable-jit.ps1`   | Script to automate JIT access setup       |
| `jit-access.bicep` | Infrastructure as code to integrate JIT   |
| `jit-policy.json`  | JSON structure for defining access policy |


#🔍 Monitoring Access Requests
Once enabled:

Go to Microsoft Defender for Cloud

Navigate to Just-In-Time VM Access

Review access history and pending requests

#🔐 Best Practices
Limit JIT to developers, admins, or automation users

Use RBAC to control who can request JIT access

Regularly audit access logs

Combine JIT with NSG and Diagnostic Settings


