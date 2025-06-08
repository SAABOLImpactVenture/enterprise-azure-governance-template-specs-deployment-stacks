// Key Vault with private endpoint for identity resources
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Key Vault name')
param keyVaultName string = 'kv-identity-${uniqueString(resourceGroup().id)}'

@description('Azure AD tenant ID')
param tenantId string

@description('ID of the identity VNet')
param vnetId string

@description('Name of the subnet for private endpoints')
param privateEndpointSubnetName string = 'snet-private-endpoints'

@description('SKU name for Key Vault')
param skuName string = 'premium'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  workload: 'identity'
  deployment: 'bicep'
}

// Reference the subnet for private endpoint
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${split(vnetId, '/')[8]}/${privateEndpointSubnetName}'
}

// Create Key Vault with enhanced security
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// Create private endpoint for Key Vault
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${keyVaultName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'connection-to-${keyVaultName}'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Create private DNS zone for Key Vault if specified
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

// Link the private DNS zone to the VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-to-${split(vnetId, '/')[8]}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Create A record for the private endpoint
resource privateDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: keyVaultName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

// Output Key Vault resource ID
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
