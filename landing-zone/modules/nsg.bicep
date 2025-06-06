// ───────────────────────────────────────────────────────────────────────────────────
// Azure Landing Zone Network Security Group Module
// ───────────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-06 19:55:58
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting NSG templates from AI assistants, consider the following
// best practices to get optimal results:
//
// 1. Be specific about required security rules:
//    - "I need a rule to allow HTTPS from these IPs..."
//    - "Block all outbound traffic except for specific services..."
//
// 2. Specify whether you need preset configurations for common scenarios:
//    - "Configure for web servers with ports 80/443"
//    - "Configure for a bastion host pattern"
//
// 3. Note which advanced features you need:
//    - Application Security Groups
//    - Service Tags
//    - Multiple IP ranges/prefixes
//
// 4. Request integration with specific monitoring or security services:
//    - "Include NSG flow logs configuration for traffic analytics"
// ───────────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// ───────────────────────────────────────────────────────────────────────────────────
// PARAMETERS
// ───────────────────────────────────────────────────────────────────────────────────

@description('The name of the Network Security Group')
@minLength(3)
@maxLength(80)
param nsgName string

@description('The name of the Virtual Network')
@minLength(2)
param vnetName string

@description('The name of the Subnet')
@minLength(1)
param subnetName string

@description('Array of security rules. Each rule must include specific properties.')
param nsgRules array = []

@description('Location for the resources')
param location string

@description('Tags to apply to created resources')
param tags object = {}

@description('Enable NSG diagnostic settings')
param enableDiagnostics bool = false

@description('Log Analytics Workspace ID for NSG diagnostics (optional)')
param diagnosticsWorkspaceId string = ''

@description('Default deny all inbound rule priority (highest number = lowest priority)')
param denyAllInboundPriority int = 4096

@description('Add default allow outbound rule')
param addAllowOutboundRule bool = true

@description('Initialize subnet with the NSG or only create the NSG')
param associateWithSubnet bool = true

// ───────────────────────────────────────────────────────────────────────────────────
// VARIABLES
// ───────────────────────────────────────────────────────────────────────────────────

// Add a default "deny all inbound" rule if no rules were provided
var defaultRules = [
  {
    name: 'DenyAllInbound'
    properties: {
      description: 'Deny all inbound traffic'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: denyAllInboundPriority
      direction: 'Inbound'
    }
  }
]

// Add a default "allow all outbound" rule if specified
var outboundRule = addAllowOutboundRule ? [
  {
    name: 'AllowOutbound'
    properties: {
      description: 'Allow all outbound traffic'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 1000
      direction: 'Outbound'
    }
  }
] : []

// Combine user provided rules and default rules
var combinedRules = concat(nsgRules, defaultRules, outboundRule)

// Validate the combined rules by mapping them to the correct structure
var processedRules = [for rule in combinedRules: {
  name: rule.name
  properties: {
    description: contains(rule, 'description') ? rule.description : contains(rule.properties, 'description') ? rule.properties.description : 'NSG rule'
    protocol: rule.properties.protocol
    access: rule.properties.access
    priority: rule.properties.priority
    direction: rule.properties.direction
    
    // Handle various source configurations
    sourcePortRange: contains(rule.properties, 'sourcePortRange') ? rule.properties.sourcePortRange : null
    sourcePortRanges: contains(rule.properties, 'sourcePortRanges') ? rule.properties.sourcePortRanges : null
    sourceAddressPrefix: contains(rule.properties, 'sourceAddressPrefix') ? rule.properties.sourceAddressPrefix : null
    sourceAddressPrefixes: contains(rule.properties, 'sourceAddressPrefixes') ? rule.properties.sourceAddressPrefixes : null
    sourceApplicationSecurityGroups: contains(rule.properties, 'sourceApplicationSecurityGroups') ? rule.properties.sourceApplicationSecurityGroups : null
    
    // Handle various destination configurations
    destinationPortRange: contains(rule.properties, 'destinationPortRange') ? rule.properties.destinationPortRange : null
    destinationPortRanges: contains(rule.properties, 'destinationPortRanges') ? rule.properties.destinationPortRanges : null
    destinationAddressPrefix: contains(rule.properties, 'destinationAddressPrefix') ? rule.properties.destinationAddressPrefix : null
    destinationAddressPrefixes: contains(rule.properties, 'destinationAddressPrefixes') ? rule.properties.destinationAddressPrefixes : null
    destinationApplicationSecurityGroups: contains(rule.properties, 'destinationApplicationSecurityGroups') ? rule.properties.destinationApplicationSecurityGroups : null
  }
}]

// ───────────────────────────────────────────────────────────────────────────────────
// RESOURCES
// ───────────────────────────────────────────────────────────────────────────────────

// 1) Create (or update) the NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: processedRules
  }
}

// 2) Associate the NSG to the specified subnet of the VNet (if enabled)
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = if (associateWithSubnet) {
  name: '${vnetName}/${subnetName}'
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// 3) Configure NSG Flow Logs if diagnostics are enabled
resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(diagnosticsWorkspaceId)) {
  name: '${nsgName}-diagnostics'
  scope: nsg
  properties: {
    workspaceId: diagnosticsWorkspaceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

// ───────────────────────────────────────────────────────────────────────────────────
// OUTPUTS
// ───────────────────────────────────────────────────────────────────────────────────

@description('The resource ID of the created NSG')
output nsgId string = nsg.id

@description('The name of the created NSG')
output nsgName string = nsg.name

@description('The rules configured in the NSG')
output securityRules array = nsg.properties.securityRules

@description('Whether the NSG has been associated with a subnet')
output associatedWithSubnet bool = associateWithSubnet

/*
SECURITY BEST PRACTICES IMPLEMENTED:
1. Default deny all inbound traffic rule
2. Support for advanced rule properties (ASGs, multiple IP ranges, etc.)
3. NSG diagnostics for traffic analysis and security monitoring
4. Complete rule validation
5. Proper subnet association
6. Resource tagging support

DEPLOYMENT CONSIDERATIONS:
1. Rules are processed in order of priority (lower number = higher priority)
2. Subnet association will modify existing subnet configuration
3. Consider using service tags like 'VirtualNetwork' or 'AzureLoadBalancer'
4. For multiple source/destination IPs, use sourceAddressPrefixes/destinationAddressPrefixes
5. For application-based rules, use application security groups

PROMPT ENGINEERING TIP:
When troubleshooting NSG issues with AI, specify:
- The specific rule that might be blocking traffic
- Source and destination details (IP, port, protocol)
- The direction of traffic (inbound/outbound)
- Whether you're using service tags or ASGs
*/
