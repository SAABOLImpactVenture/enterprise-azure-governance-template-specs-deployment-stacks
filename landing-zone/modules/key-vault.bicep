// Key Vault with private endpoint for identity resources
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Key Vault name')
@minLength(3)
@maxLength(24)
param keyVaultName string = 'kv${uniqueString(resourceGroup().id, environment)}' // Simplified name

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

// Output Key Vault resource ID
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
