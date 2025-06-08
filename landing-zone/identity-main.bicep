// Main deployment file for Identity resources
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Azure AD tenant ID')
param tenantId string

@description('Whether to deploy Azure AD Domain Services')
param deployAadds bool = true

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  workload: 'identity'
  deployment: 'bicep'
}

// Deploy Identity VNet and subnets
module identityNetwork '../modules/identity-network.bicep' = {
  name: 'identity-network-deployment'
  params: {
    location: location
    environment: environment
    tags: tags
  }
}

// Deploy Key Vault
module keyVault '../modules/key-vault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    location: location
    environment: environment
    tenantId: tenantId
    vnetId: identityNetwork.outputs.vnetId
    tags: tags
  }
  dependsOn: [
    identityNetwork
  ]
}

// Deploy Managed Identities
module managedIdentities '../modules/managed-identities.bicep' = {
  name: 'managed-identities-deployment'
  params: {
    location: location
    environment: environment
    tags: tags
  }
}

// Deploy Azure AD Domain Services if specified
module aadds '../modules/aadds.bicep' = if (deployAadds) {
  name: 'aadds-deployment'
  params: {
    location: location
    environment: environment
    domainName: 'aadds.${tenantId}.onmicrosoft.com'
    vnetId: identityNetwork.outputs.vnetId
    tags: tags
  }
  dependsOn: [
    identityNetwork
  ]
}

// Outputs
output vnetId string = identityNetwork.outputs.vnetId
output vnetName string = identityNetwork.outputs.vnetName
output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVault.outputs.keyVaultName
output appIdentityId string = managedIdentities.outputs.appIdentityId
output dataWorkloadIdentityId string = managedIdentities.outputs.dataWorkloadIdentityId
output automationIdentityId string = managedIdentities.outputs.automationIdentityId
output aaddsId string = deployAadds ? aadds.outputs.aaddsId : ''
