// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/nsg.bicep
// Description: Creates a Network Security Group (NSG) and associates it to
// the specified subnet of the VNet inside the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
@description('The name of the Network Security Group.')
param nsgName string

@description('The name of the Virtual Network.')
param vnetName string

@description('The name of the Subnet.')
param subnetName string

@description('Array of security rules. Each rule must include: name, protocol, priority, direction, access, sourcePortRange, destinationPortRange, sourceAddressPrefix, destinationAddressPrefix, description.')
param nsgRules array

@description('Location for the resources.')
param location string

// 1) Create (or update) the NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      for rule in nsgRules: {
        name: rule.name
        protocol: rule.protocol // Mandatory field; ensure valid values like "Tcp", "Udp", or "*"
        priority: rule.priority
        direction: rule.direction
        access: rule.access
        sourcePortRange: rule.sourcePortRange
        destinationPortRange: rule.destinationPortRange
        // Removed invalid properties
      }
    ]
  }
}

// 2) Associate the NSG to the specified subnet of the VNet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: null // Required by the API unless you use `existing`
    networkSecurityGroup: {
      id: nsg.id
    }
  }
  // Marking as 'existing' so only the NSG association is changed, not the subnet definition.
  existing: true
}

output nsgId string = nsg.id
