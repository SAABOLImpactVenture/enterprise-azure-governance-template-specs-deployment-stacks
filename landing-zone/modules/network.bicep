// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/network.bicep
// Description: Creates a Virtual Network (+ default subnet) inside its RG.
// Metrics, NSG, etc. are applied in separate modules.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param vnetName      string
param addressPrefix string
param subnetPrefix  string
param location      string

// Create (or update) the Virtual Network
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

// Outputs so the parent can reference them
output vnetId   string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
