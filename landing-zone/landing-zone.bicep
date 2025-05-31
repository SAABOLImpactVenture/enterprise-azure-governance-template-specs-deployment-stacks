// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/landing-zone.bicep
// Description: Deploys a VNet + diagnostic settings into a single resource group.
//              Must be deployed with "az deployment group create" because
//              targetScope = 'resourceGroup'.
// ─────────────────────────────────────────────────────────────────────────────

// 1) Declare that this template is scoped to a Resource Group
targetScope = 'resourceGroup'

// ─────────────────────────────────────────────────────────────────────────────
// 2) Parameters
// ─────────────────────────────────────────────────────────────────────────────

// If you omit "location", Bicep will use the resource group's location by default.
param location string = resourceGroup().location

// Name of the Virtual Network
param vnetName    string = 'landingZone-vnet'

// Address space for the VNet
param addressPrefix string = '10.0.0.0/16'

// Address prefix for the default subnet
param subnetPrefix  string = '10.0.1.0/24'

// The workspace resource ID where diagnostic logs/metrics should go.
// e.g. "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/MyLogAnalytics"
param diagnosticsWorkspaceId string

// ─────────────────────────────────────────────────────────────────────────────
// 3) Resources
// ─────────────────────────────────────────────────────────────────────────────

// 3.1) Create (or update) a Virtual Network with a single "default" subnet
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name:     vnetName
  location: location
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

// 3.2) Configure diagnostic settings on that VNet so that NSG/NIC flow logs (for example)
//      are sent to the provided Log Analytics workspace.
resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vnetDiagnostics'
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
// 4) (Optional) Outputs
// ─────────────────────────────────────────────────────────────────────────────

// Export the VNet ID and subnet ID in case downstream scripts need to reference them.
output vnetId    string = vnet.id
output subnetId  string = vnet.properties.subnets[0].id
