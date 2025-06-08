// Azure AD Domain Services for cloud-only environment
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Domain name for AADDS')
param domainName string = 'aadds.contoso.com'

@description('SKU for AADDS')
@allowed(['Standard', 'Enterprise', 'Premium'])
param sku string = 'Standard'

@description('ID of the identity VNet')
param vnetId string

@description('Name of the subnet for AADDS')
param aaddsSubnetName string = 'snet-domain-services'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  workload: 'identity'
  deployment: 'bicep'
}

// Extract VNet name from VNet ID
var vnetName = split(vnetId, '/')[8]

// Reference the subnet for AADDS
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${vnetName}/${aaddsSubnetName}'
}

// Create a Network Security Group for AADDS
resource aaddsNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-aadds'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowLDAPS'
        properties: {
          priority: 201
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '636'
        }
      }
      {
        name: 'AllowLDAP'
        properties: {
          priority: 202
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '389'
        }
      }
      {
        name: 'AllowKerberos'
        properties: {
          priority: 203
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '88'
        }
      }
    ]
  }
}

// Associate NSG with the subnet
resource subnetNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: '${vnetName}/${aaddsSubnetName}'
  properties: {
    addressPrefix: subnet.properties.addressPrefix
    networkSecurityGroup: {
      id: aaddsNsg.id
    }
    delegations: subnet.properties.delegations
    serviceEndpoints: subnet.properties.serviceEndpoints
    privateEndpointNetworkPolicies: subnet.properties.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: subnet.properties.privateLinkServiceNetworkPolicies
  }
}

// Deploy Azure AD Domain Services
resource aadds 'Microsoft.AAD/domainServices@2022-12-01' = {
  name: 'aadds-${environment}'
  location: location
  tags: tags
  properties: {
    domainName: domainName
    domainConfigurationType: 'FullySynced'
    sku: sku
    replicaSets: [
      {
        subnetId: subnet.id
        location: location
      }
    ]
  }
  dependsOn: [
    subnetNsgAssociation
  ]
}

// Output AADDS resource ID
output aaddsId string = aadds.id
output aaddsName string = aadds.name
