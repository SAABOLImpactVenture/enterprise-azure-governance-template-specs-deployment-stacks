// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/network.bicep
// Description: Creates a Virtual Network + default subnet inside the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param vnetName      string
param addressPrefix string
param subnetPrefix  string
param location      string

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

// Outputs so the parent orchestrator can reference them
output vnetId   string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
