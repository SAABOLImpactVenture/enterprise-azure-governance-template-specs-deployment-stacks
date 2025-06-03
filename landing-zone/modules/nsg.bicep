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
    securityRules: [
      for rule in nsgRules: {
        name: rule.name
        protocol: rule.protocol
        priority: rule.priority
        direction: rule.direction
        access: rule.access
        sourcePortRange: rule.sourcePortRange
        destinationPortRange: rule.destinationPortRange
        sourceAddressPrefix: rule.sourceAddressPrefix
        destinationAddressPrefix: rule.destinationAddressPrefix
        description: rule.description
      }
    ]
  }
}

// 2) Associate the NSG to the specified subnet of the VNet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

output nsgId string = nsg.id
