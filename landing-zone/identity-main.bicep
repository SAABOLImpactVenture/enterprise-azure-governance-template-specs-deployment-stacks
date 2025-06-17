// ─────────────────────────────────────────────────────────────────────────────
// Main deployment file for Identity resources
// ─────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-17 12:33:00
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting Bicep templates for identity resource orchestration from AI assistants, consider these best practices:
//
// 1. Specify required parameters and module dependencies:
//    - location: Azure region for all resources
//    - environment: Environment name for tagging and context
//    - tenantId: Azure AD tenant identifier
//    - deployAadds: Boolean to toggle Azure AD Domain Services deployment
//    - tags: Object for consistent resource tagging
//
// 2. Clearly describe each module's role and dependencies in the identity stack:
//    - Deploy an identity VNet first and use its outputs as inputs for downstream modules.
//    - Deploy Key Vault, Managed Identities, and optionally Azure AD Domain Services.
//    - Use `dependsOn` to ensure correct deployment order.
//
// 3. Parameterize as much as possible for reusability across environments:
//    - Allow toggling of optional components (e.g., Azure AD DS) via parameters.
//    - Pass outputs between modules for dynamic wiring.
//
// 4. Use descriptive output variables to facilitate integration with downstream Bicep modules or automation pipelines.
//
// 5. Document the intended use case and rationale for each module, especially when integrating identity, network, and vault resources.
//
// ─────────────────────────────────────────────────────────────────────────────

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
