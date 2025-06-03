// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/nsg.bicep
// Description: Creates a Network Security Group (NSG) and associates it to
// the specified subnet of the VNet inside the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param nsgName    string
param vnetName   string
param subnetName string
param nsgRules   array
param location   string

// 1) Create (or update) the NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name:     nsgName
  location: location
  properties: {
    securityRules: nsgRules // Use the parameter directly
  }
}

// 2) Associate the NSG to the specified subnet of the VNet
//
//    Instead of using `parent`, we fully qualify the child resource name
//    in the format: "<VNetName>/<SubnetName>/<NSGName>".
//
resource assoc 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}/${subnetName}/${nsgName}'
  properties: {
    id: nsg.id
  }
}

output nsgId string = nsg.id
