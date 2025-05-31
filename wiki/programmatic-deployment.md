# 🤖 Programmatic Deployment of Landing Zone

## 📌 Overview

This page provides a hands-on guide for **deploying the Azure Landing Zone programmatically** using tools like **Azure CLI**, **PowerShell**, and **GitHub Actions**. It is designed for architects and engineers who want to automate infrastructure setup for **Enterprise-scale** environments and integrate these patterns into a **Cloud Center of Excellence (CCoE)** strategy.

---

## 🧰 Tools & Technologies

- **Azure CLI**
- **Azure PowerShell**
- **Bicep**
- **GitHub Actions**
- **ARM Template Specs** (modern alternative to Azure Blueprints)

---

## 📁 Directory Structure

/landing-zone
├── bicep/
│ ├── landing-zone.bicep
│ ├── network.bicep
│ ├── nsg.bicep
│ ├── diagnostic.bicep
│ ├── jit-access.bicep
│ ├── policy.bicep
│ └── roleAssignment.bicep
├── parameters/
│ └── landing-zone.parameters.json
├── scripts/
│ ├── enable-diagnostic.ps1
│ ├── enable-jit.ps1
│ └── configure-nsg.ps1
├── .github/workflows/
│ └── landing-zone-ci.yml


---

## 🛠 Azure CLI Deployment

```bash
az deployment sub create \
  --location eastus \
  --template-file ./bicep/landing-zone.bicep \
  --parameters ./parameters/landing-zone.parameters.json

#Powershell
Connect-AzAccount

New-AzSubscriptionDeployment `
  -Location "eastus" `
  -TemplateFile "./bicep/landing-zone.bicep" `
  -TemplateParameterFile "./parameters/landing-zone.parameters.json"


#GitHub Actions Deployment

name: Deploy Landing Zone

on:
  push:
    paths:
      - 'bicep/**'
      - 'parameters/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Landing Zone
        uses: azure/arm-deploy@v1
        with:
          scope: subscription
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          region: 'eastus'
          template: './bicep/landing-zone.bicep'
          parameters: './parameters/landing-zone.parameters.json'

#Template Specs
az ts create \
  --name landingZoneSpec \
  --version 1.0 \
  --location eastus \
  --template-file ./bicep/landing-zone.bicep \
  --display-name "Landing Zone Template Spec"

#Bash
az deployment sub create \
  --location eastus \
  --template-spec "/subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.Resources/templateSpecs/landingZoneSpec/versions/1.0"
