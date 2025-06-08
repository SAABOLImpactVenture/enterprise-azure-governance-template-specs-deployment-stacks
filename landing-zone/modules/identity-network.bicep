// Identity Network for cloud-only deployment
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Address space for the identity virtual network')
param addressPrefix string = '10.2.0.0/16'

@description('Name of the identity virtual network')
param vnetName string = 'vnet-identity'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  workload: 'identity'
  deployment: 'bicep'
}

// Define subnets
var subnets = [
  {
    name: 'snet-identity-services'
    properties: {
      addressPrefix: '10.2.0.0/24'
      privateEndpointNetworkPolicies: 'Disabled'
    }
  }
  {
    name: 'snet-domain-services'
    properties: {
      addressPrefix: '10.2.1.0/24'
    }
  }
  {
    name: 'snet-private-endpoints'
    properties: {
      addressPrefix: '10.2.2.0/24'
      privateEndpointNetworkPolicies: 'Disabled'
    }
  }
]

// Create Virtual Network
resource identityVNet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
  }
}

// Output the VNet ID for use in other deployments
output vnetId string = identityVNet.id
output vnetName string = identityVNet.name
