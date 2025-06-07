param location string = resourceGroup().location
param hubNetworkName string = 'vnet-hub'
param addressPrefix string = '10.0.0.0/16'
param enableDdosProtection bool = false

// Hub network with key subnets
resource hubNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: hubNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        }
      }
      {
        name: 'BastionSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        }
      }
      {
        name: 'ManagementSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 2)
        }
      }
    ]
    enableDdosProtection: enableDdosProtection
  }
}

// Azure Firewall for centralized security
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: 'fw-hub'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubNetwork.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-fw-hub'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: 'bas-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubNetwork.id}/subnets/BastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-bastion-hub'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Private DNS zones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azure.com'
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/link-hub'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: hubNetwork.id
    }
    registrationEnabled: false
  }
}

output hubNetworkId string = hubNetwork.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
