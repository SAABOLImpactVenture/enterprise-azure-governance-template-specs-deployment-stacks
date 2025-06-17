// ─────────────────────────────────────────────────────────────────────────────
// Identity Network for cloud-only deployment
// ─────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-17 12:35:02
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting AI-generated or AI-refactored Bicep templates for identity networks, consider the following best practices:
//
// 1. Clearly specify all key parameters:
//    - location: Azure region for all resources
//    - environment: Deployment environment (e.g., production, dev, test)
//    - addressPrefix: CIDR block for the identity virtual network
//    - vnetName: Name of the identity VNet (parameterized for reusability)
//    - tags: Tags for resource classification and automation
//
// 2. Describe subnet layout requirements for identity workloads:
//    - Identity services subnet (with private endpoint policies, if needed)
//    - Domain services subnet
//    - Private endpoints subnet (with network policies disabled)
//    - Parameterize subnet prefixes if customization is needed for different environments.
//
// 3. Indicate if integration with other modules (like Key Vault, AD DS, or managed identities) will use outputs from this module (e.g., vnetId).
//
// 4. Use descriptive output names for downstream consumption in orchestration or automation pipelines.
//
// 5. State networking and security best practices required for identity workloads, such as using private endpoints and disabling network policies as appropriate.
//
// ─────────────────────────────────────────────────────────────────────────────

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
