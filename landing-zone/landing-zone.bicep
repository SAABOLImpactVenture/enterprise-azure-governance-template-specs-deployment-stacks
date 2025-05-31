// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/landing-zone.bicep
// Description: Subscription‐scoped landing‐zone that:
//   1) Creates (or updates) a Resource Group named "landingZone-RG"
//   2) Inside that RG, creates a Virtual Network + default subnet
//   3) Attaches Diagnostic Settings on that VNet pointing to a Log Analytics workspace
//
// Because we are creating a Resource Group from subscription scope, we must deploy
// this with `az deployment sub create …`. Therefore:
targetScope = 'subscription'

// ─────────────────────────────────────────────────────────────────────────────
// 1) Parameters
// ─────────────────────────────────────────────────────────────────────────────

// Location for the new Resource Group (and all child resources inside it)
param location string = 'eastus'

// Name of the Resource Group to create or update
param rgName string = 'landingZone-RG'

// Name of the Virtual Network to create inside that RG
param vnetName string = 'landingZone-vnet'

// Address space to use on the VNet
param addressPrefix string = '10.0.0.0/16'

// Address prefix of the default subnet inside the VNet
param subnetPrefix string = '10.0.1.0/24'

// The full resource ID of your Log Analytics workspace, for example:
// "/subscriptions/00000000-0000-0000-0000-000000000000/
//    resourceGroups/LogAnalytics-RG/
//    providers/Microsoft.OperationalInsights/workspaces/MyLAWorkspace"
param diagnosticsWorkspaceId string

// ─────────────────────────────────────────────────────────────────────────────
// 2) Resources
// ─────────────────────────────────────────────────────────────────────────────

// 2.1) Create (or update) the RG named in `rgName`
//     API version must be a valid ASCII string: "2021-04-01"
resource landingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:     rgName
  location: location
}

// 2.2) Create a Virtual Network *inside* that RG
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name:  vnetName
  scope: landingRG    // This ensures the VNet is deployed into landingRG
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

// 2.3) Configure Diagnostic Settings on that VNet so logs/metrics flow to the workspace
resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'vnetDiagnostics'
  scope: vnet         // Apply this diagnostic setting *to* the VNet resource
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
    ]
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) Outputs (optional) – in case you need to reference them downstream
// ─────────────────────────────────────────────────────────────────────────────

output landingRGId string = landingRG.id
output vnetId       string = vnet.id
output subnetId     string = vnet.properties.subnets[0].id
