// ─────────────────────────────────────────────────────────────────────────────────
// File: landing‐zone/landing‐zone.bicep
// Description: Subscription‐scoped landing‐zone that:
//   1) Creates a new resource group: "landingZone‐RG"
//   2) Inside that RG, creates a Virtual Network + default subnet
//   3) Attaches Diagnostic Settings (logs & metrics) on that VNet to a Log Analytics workspace
//
// NOTE: Because this file creates a Resource Group first, it must be deployed at
//       subscription scope using `az deployment sub create`. We declare:
//         targetScope = 'subscription'
// ─────────────────────────────────────────────────────────────────────────────────

// 1) Declare subscription scope
targetScope = 'subscription'

// 2) Parameters
// ─────────────────────────────────────────────────────────────────────────────────

// Location for the new Resource Group (and VNet inside it)
param location string = 'eastus'

// Name of the Resource Group to create for the landing zone
// (You may change this default; the template will create or update it.)
param rgName string = 'landingZone‐RG'

// Name of the Virtual Network to create inside that RG
param vnetName string = 'landingZone‐vnet'

// Address space to use on the VNet
param addressPrefix string = '10.0.0.0/16'

// Address prefix of the default subnet inside the VNet
param subnetPrefix string = '10.0.1.0/24'

// The full resource ID of your Log Analytics workspace, e.g.:
// "/subscriptions/00000000‐0000‐0000‐0000‐000000000000/
//    resourceGroups/LogAnalytics‐RG/
//    providers/Microsoft.OperationalInsights/workspaces/MyLAWorkspace"
param diagnosticsWorkspaceId string

// 3) Resources
// ─────────────────────────────────────────────────────────────────────────────────

// 3.1) Create (or update) the landing‐zone Resource Group
resource landingRG 'Microsoft.Resources/resourceGroups@2021‐04‐01' = {
  name:     rgName
  location: location
}

// 3.2) Create a Virtual Network in that Resource Group
resource vnet 'Microsoft.Network/virtualNetworks@2022‐09‐01' = {
  name:  vnetName
  scope: landingRG
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

// 3.3) Attach Diagnostic Settings to the VNet so that logs & metrics go to your workspace
resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021‐05‐01‐preview' = {
  name:  'vnetDiagnostics'
  scope: vnet
  properties: {
    workspaceId: diagnosticsWorkspaceId

    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled:  true
        retentionPolicy: {
          enabled: false
          days:    0
        }
      }
      // You can add more log categories here if needed
    ]

    metrics: [
      {
        category: 'AllMetrics'
        enabled:  true
        retentionPolicy: {
          enabled: false
          days:    0
        }
      }
      // You can add more metric categories here if needed
    ]
  }
}

// 4) Outputs (optional) – in case you need to reference them downstream
// ─────────────────────────────────────────────────────────────────────────────────

output landingRGId string = landingRG.id
output vnetId       string = vnet.id
output subnetId     string = vnet.properties.subnets[0].id
