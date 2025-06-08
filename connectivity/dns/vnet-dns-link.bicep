// ==========================================================================
// Virtual Network to Private DNS Zone Link
// ==========================================================================
// PROMPT ENGINEERING GUIDANCE:
// This template links a VNet to a Private DNS zone with the following capabilities:
// - Links an existing private DNS zone to a virtual network
// - Controls whether auto-registration is enabled for VM records
// - Works with centralized DNS architecture in hub/spoke deployments
// - Supports both hub-managed and spoke-managed DNS zones
//
// USAGE CONTEXT:
// - Used when you need DNS resolution across the enterprise
// - Critical for private endpoints to resolve properly across VNets
// - Enables private Azure services like Storage, KeyVault, etc.
// 
// PARAMETER GUIDANCE:
// - privateDnsZoneName: Use the FQDN of the service (privatelink.blob.core.windows.net)
// - vnetLinkName: Best practice is "link-{vnetname}-{zonename}" format
// - registrationEnabled: Set to true only for the VNet that should register records
// - virtualNetworkId: Must be the full resource ID including subscription
//
// CUSTOM NAMING CONVENTION:
// This template enforces consistent naming conventions for DNS links:
// - link-{vnetname}-{modified-zone-name}
// - where modified-zone-name replaces dots with hyphens

@description('Name of the private DNS zone')
param privateDnsZoneName string

@description('Name for the virtual network link')
param vnetLinkName string

@description('Resource ID of the virtual network to link')
param virtualNetworkId string

@description('Whether to enable auto-registration of VM records')
param registrationEnabled bool = false

// Create virtual network link
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}/${vnetLinkName}'
  location: 'global'
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

// Output the resource ID of the link
output vnetLinkId string = privateDnsZoneVnetLink.id
