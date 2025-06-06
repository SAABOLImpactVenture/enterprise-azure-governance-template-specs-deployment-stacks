// ───────────────────────────────────────────────────────────────────────────────────
// Azure Landing Zone Virtual Network Module
// ───────────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-06 19:53:32
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting network infrastructure from AI assistants, consider the following
// best practices to get optimal results:
//
// 1. Explicitly specify network parameters with CIDR notation examples:
//    - "Create a VNet with address space 10.0.0.0/16"
//    - "Include a subnet with CIDR block 10.0.1.0/24"
//
// 2. Be clear about which Azure networking features you need:
//    - "Include NSG with these specific rules..."
//    - "Enable service endpoints for these Azure services..."
//    - "Configure DDoS protection standard/basic"
//
// 3. Request validation with @minLength/@maxLength decorators for parameters
//    to ensure naming convention compliance
//
// 4. Specify networking best practices you want included:
//    - "Implement network segregation with multiple subnets"
//    - "Apply least-privilege NSG rules"
// ───────────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// ───────────────────────────────────────────────────────────────────────────────────
// PARAMETERS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Name of the virtual network')
@minLength(5)
@maxLength(64)
param vnetName string

@description('Address space for the virtual network in CIDR notation')
@minLength(9)  // Minimum length for a valid CIDR notation (e.g., 10.0.0.0/8)
param addressPrefix string

@description('Address range for the default subnet in CIDR notation')
@minLength(9)
param subnetPrefix string

@description('Azure region where resources will be deployed')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Enable DDoS Protection Standard')
param enableDdosProtection bool = false

@description('Enable VM Protection for all subnets')
param enableVmProtection bool = true

@description('Array of service endpoints to enable on the default subnet')
@allowed([
  'Microsoft.AzureActiveDirectory'
  'Microsoft.AzureCosmosDB'
  'Microsoft.ContainerRegistry'
  'Microsoft.EventHub'
  'Microsoft.KeyVault'
  'Microsoft.ServiceBus'
  'Microsoft.Sql'
  'Microsoft.Storage'
  'Microsoft.Web'
])
param serviceEndpoints array = []

@description('Create a Network Security Group for the default subnet')
param createNetworkSecurityGroup bool = true

// ───────────────────────────────────────────────────────────────────────────────────
// VARIABLES 
// ───────────────────────────────────────────────────────────────────────────────────

var nsgName = '${vnetName}-default-nsg'

// Service endpoint configuration
var serviceEndpointConfigs = [for service in serviceEndpoints: {
  service: service
}]

// ───────────────────────────────────────────────────────────────────────────────────
// RESOURCES
// ───────────────────────────────────────────────────────────────────────────────────

// Network Security Group (conditional)
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = if (createNetworkSecurityGroup) {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Allow HTTPS inbound - critical for Azure services and VM extensions
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow HTTPS inbound'
        }
      }
      // Deny all other inbound by default - zero trust approach
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    // DDoS Protection configuration
    enableDdosProtection: enableDdosProtection
    // VM protection prevents VMs from being attached to subnets without NSGs
    enableVmProtection: enableVmProtection
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: subnetPrefix
          // Conditionally reference NSG
          networkSecurityGroup: createNetworkSecurityGroup ? {
            id: nsg.id
          } : null
          // Service endpoints if specified
          serviceEndpoints: serviceEndpoints != [] ? serviceEndpointConfigs : null
        }
      }
    ]
  }
}

// ───────────────────────────────────────────────────────────────────────────────────
// OUTPUTS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Resource ID of the created virtual network')
output vnetId string = vnet.id

@description('Resource ID of the default subnet')
output subnetId string = vnet.properties.subnets[0].id

@description('Name of the created virtual network')
output vnetName string = vnet.name

@description('Name of the default subnet')
output subnetName string = vnet.properties.subnets[0].name

@description('Address space of the virtual network')
output addressSpace array = vnet.properties.addressSpace.addressPrefixes

@description('Resource ID of the network security group (if created)')
output nsgId string = createNetworkSecurityGroup ? nsg.id : ''

/*
DEPLOYMENT CONSIDERATIONS:
1. Ensure the address spaces don't overlap with existing networks if using VNet peering
2. The default subnet configuration is basic and should be extended for production
3. For production, consider creating dedicated subnets for different workloads
4. NSG rules should be customized based on specific workload requirements
5. Service endpoints increase security but may require additional firewall rules

NETWORKING BEST PRACTICES IMPLEMENTED:
1. Default deny rule for inbound traffic
2. Optional DDoS protection
3. Optional VM protection
4. Service endpoint support for Azure PaaS services
5. Resource tagging support

PROMPT ENGINEERING TIP:
When troubleshooting network issues with AI, specify exactly which components are 
involved (VNet, NSG, subnet), the error message, and specific flow that's failing
(e.g., "VM in subnet X can't reach Azure SQL using service endpoint")
*/
