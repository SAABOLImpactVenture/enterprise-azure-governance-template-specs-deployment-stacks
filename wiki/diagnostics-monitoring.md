# 📊 Diagnostic and Monitoring Strategy

This document outlines how diagnostic settings and monitoring are configured across the Azure DevTest Lab and associated infrastructure to ensure observability, compliance, and issue resolution capabilities.

---

## 🧠 Overview

Azure diagnostics and monitoring are critical for:
- Capturing logs and metrics from virtual machines, networks, and resources.
- Auditing system behaviors for compliance.
- Alerting for anomalies and operational issues.
- Enabling dashboards for visibility via Azure Monitor and Log Analytics.

---

## 🔍 Components

### 1. **Log Analytics Workspace**
- Central logging destination for all diagnostic data.
- Used for querying logs with Kusto Query Language (KQL).
- Enables cross-resource insights and centralized monitoring.

### 2. **Diagnostic Settings**
- Applied to:
  - Virtual Machines
  - Network Interfaces
  - Disks (optional)
- Categories include:
  - **Metrics**
  - **Boot Diagnostics**
  - **Guest OS Logs**
  - **Performance Counters**

### 3. **Azure Monitor Integration**
- Metrics are automatically collected and visualized via:
  - **Azure Monitor Metrics Explorer**
  - **Workbooks**
  - **Alerts** based on thresholds

---

## ⚙️ Deployment Automation

### ✅ Bicep Module
- **`diagnostic.bicep`** defines the diagnostic settings tied to Log Analytics Workspace.
- Accepts parameters:
  - `diagnosticsWorkspaceId`
  - Resource name/type for target VM or NIC

### 🛠 PowerShell Automation
- **`enable-diagnostic.ps1`** script configures diagnostics post-deployment if needed.
  ```powershell
  .\enable-diagnostic.ps1 -resourceGroup "Dev_Test_Lab-demosmartcontract-vm-017910" `
                          -vmName "demosmartcontract-vm" `
                          -workspaceId "/subscriptions/<sub-id>/resourceGroups/<log-rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
