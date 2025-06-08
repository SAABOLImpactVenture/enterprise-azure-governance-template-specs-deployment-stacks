// User-assigned managed identities for workloads
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'production'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  workload: 'identity'
  deployment: 'bicep'
}

// Create user-assigned managed identities
resource appManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-app-services'
  location: location
  tags: tags
}

resource dataWorkloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-data-workloads'
  location: location
  tags: tags
}

resource automationIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-automation'
  location: location
  tags: tags
}

// Outputs for reference in other deployments
output appIdentityId string = appManagedIdentity.id
output appIdentityPrincipalId string = appManagedIdentity.properties.principalId

output dataWorkloadIdentityId string = dataWorkloadIdentity.id
output dataWorkloadPrincipalId string = dataWorkloadIdentity.properties.principalId

output automationIdentityId string = automationIdentity.id
output automationPrincipalId string = automationIdentity.properties.principalId
