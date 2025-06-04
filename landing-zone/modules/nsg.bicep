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
  name:     nsgName
  location: location
  properties: {
    securityRules: [
      for rule in nsgRules: {
        name: rule.name
        properties: { // NSG rules need their own 'properties' block
          protocol: rule.protocol
          priority: rule.priority
          direction: rule.direction
          access: rule.access
          sourcePortRange: rule.sourcePortRange
          destinationPortRange: rule.destinationPortRange
          sourceAddressPrefix: rule.sourceAddressPrefix // Assuming these are intended to be used
          destinationAddressPrefix: rule.destinationAddressPrefix // Assuming these are intended to be used
          description: rule.description // Assuming these are intended to be used
        }
      }
    ]
  }
}

// 2) Associate the NSG to the specified subnet of the VNet
//    To update an existing subnet (e.g., to associate an NSG),
//    you define the resource as if creating it, but Bicep performs an update.
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${vnetName}/${subnetName}' // Correctly identifies the existing subnet under the VNet
  properties: {
    // Only specify the properties you intend to change or set.
    // For associating an NSG, this is the key property.
    networkSecurityGroup: {
      id: nsg.id
    }
    // Do NOT include 'addressPrefix: null' or other properties
    // unless you explicitly intend to modify them on the existing subnet.
    // If the subnet already has an addressPrefix, omitting it here
    // means it will not be changed.
  }
  // The 'existing: true' property is NOT used here for this update pattern to prevent Error BCP104
}

output nsgId string = nsg.id
