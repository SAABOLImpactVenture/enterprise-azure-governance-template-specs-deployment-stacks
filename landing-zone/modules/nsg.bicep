// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/nsg.bicep
// Description: Creates a Network Security Group (NSG) and associates it to a
// subnet within the VNet inside its RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param nsgName    string
param vnetName   string
param subnetName string
param rules      array
param location   string

// 1) Create (or update) the NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name:     nsgName
  location: location
  properties: {
    securityRules: rules
  }
}

// 2) Associate the NSG to the specified subnet of the VNet
resource assoc 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroups@2022-05-01' = {
  name:   '${vnetName}/${subnetName}/${nsgName}'
  parent: resourceId('Microsoft.Network/virtualNetworks', vnetName, 'subnets', subnetName)
  properties: {
    id: nsg.id
  }
}

output nsgId string = nsg.id
