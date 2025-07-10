// Default location from resource group context
param location string = resourceGroup().location
// Hub network name following Azure naming conventions
param hubNetworkName string = 'vnet-hub'
// Main address space for the hub network - typically a /16 for enterprise deployments
param addressPrefix string = '10.0.0.0/16'
// DDoS protection is optional but recommended for production environments
param enableDdosProtection bool = false

// Hub network with key subnets for centralized services
resource hubNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: hubNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix // Single address space for the hub network
      ]
    }
    subnets: [
      {
        // Azure Firewall requires a subnet named exactly 'AzureFirewallSubnet' with minimum /26
        name: 'AzureFirewallSubnet'
        properties: {
          // cidrSubnet calculates the first /24 subnet (10.0.0.0/24) from the /16 address space
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        }
      }
      {
        // Azure Bastion requires a subnet named exactly 'AzureBastionSubnet' with minimum /27
        name: 'BastionSubnet'
        properties: {
          // cidrSubnet calculates the second /24 subnet (10.0.1.0/24) from the /16 address space
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        }
      }
      {
        // Management subnet for shared services and administrative resources
        name: 'ManagementSubnet'
        properties: {
          // cidrSubnet calculates the third /24 subnet (10.0.2.0/24) from the /16 address space
          addressPrefix: cidrSubnet(addressPrefix, 24, 2)
        }
      }
    ]
    // Enable DDoS protection for production environments (additional cost applies)
    enableDdosProtection: enableDdosProtection
  }
}

// Azure Firewall for centralized security and traffic filtering in hub-spoke topology
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: 'fw-hub'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet' // VNet mode (as opposed to Virtual WAN mode)
      tier: 'Standard' // Standard tier provides essential security features
    }
    // Alert mode logs threats but doesn't block - change to 'Deny' for active protection
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            // Must reference the AzureFirewallSubnet created above
            id: '${hubNetwork.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            // Static public IP for consistent firewall endpoint
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

// Public IP for Azure Firewall - must be Standard SKU for Azure Firewall compatibility
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-fw-hub'
  location: location
  sku: {
    name: 'Standard' // Standard SKU required for Azure Firewall
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Static allocation required for Standard SKU
  }
}

// Azure Bastion for secure RDP/SSH access without exposing VMs to internet
resource bastion 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: 'bas-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            // Must reference the AzureBastionSubnet (formerly BastionSubnet)
            id: '${hubNetwork.id}/subnets/BastionSubnet'
          }
          publicIPAddress: {
            // Dedicated public IP for Bastion service
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// Public IP for Azure Bastion - provides secure access point for remote management
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-bastion-hub'
  location: location
  sku: {
    name: 'Standard' // Standard SKU required for Azure Bastion
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Static allocation for consistent access endpoint
  }
}

// Private DNS zones for internal name resolution and private endpoints
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azure.com'
  location: 'global' // Private DNS zones are global resources
  properties: {}
}

// Link the private DNS zone to the hub network for name resolution
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/link-hub'
  location: 'global' // DNS zone links are also global resources
  properties: {
    virtualNetwork: {
      id: hubNetwork.id // Link to the hub network created above
    }
    registrationEnabled: false // Only enable registration for specific scenarios
  }
}

// Output the hub network ID for use in other modules (e.g., spoke networks, peering)
output hubNetworkId string = hubNetwork.id
// Output the firewall's private IP for routing configuration in spoke networks
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
