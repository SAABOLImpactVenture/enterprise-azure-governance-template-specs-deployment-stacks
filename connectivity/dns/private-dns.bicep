// =============================================================================
// Azure Private DNS Zone Deployment Module
// Last Updated: 2025-06-17 12:39:40
// Author: GEP-V
// =============================================================================
//
// PROMPT ENGINEERING NOTES:
// When requesting AI-generated or AI-reviewed Bicep templates for Private DNS in Azure, follow these best practices:
//
// 1. Clearly parameterize all aspects to maximize reusability and automation:
//    - location: Azure region context for resource deployment (typically 'global' for DNS).
//    - tags: Tagging for environment, deployment, and audit traceability.
//    - hubVnetId: Resource ID of the hub virtual network for DNS linking.
//    - spokeVnetIds: Array of spoke VNet IDs for DNS linking (parameterized for flexibility).
//    - linkNameSuffix: Optional suffix for DNS zone link names for uniqueness and readability.
//    - privateDnsZones: Array of private DNS zones to be created and linked.
//
// 2. Ensure array-driven resource creation for scalable and DRY (Don't Repeat Yourself) deployments:
//    - Use array loops for creating DNS zones and virtual network links.
//    - Support arbitrary numbers of zones and spokes.
//
// 3. Document default values and provide rationale for any hardcoded lists (e.g., default private DNS zones for common Azure services).
//
// 4. When linking DNS zones, clarify whether registration is enabled or disabled, and why.
//
// 5. Output critical resource IDs for downstream automation or visibility.
//
// 6. When using this pattern for a hub-and-spoke topology, explicitly note the intended design (central hub with multiple spokes sharing DNS zones).
//
// =============================================================================

@description('The Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {
  environment: 'production'
  deployedBy: 'GEP-V'
  deploymentDate: '2025-06-06'
}

@description('Hub virtual network resource ID to link with private DNS zones')
param hubVnetId string

@description('Spoke virtual networks resource IDs to link with private DNS zones')
param spokeVnetIds array = []

@description('Optional suffix for DNS zone links')
param linkNameSuffix string = '-link'

@description('Private DNS zones to create and link to networks')
param privateDnsZones array = [
  'privatelink.azure-automation.net'
  'privatelink.database.windows.net'
  'privatelink.blob.core.windows.net'
  'privatelink.table.core.windows.net'
  'privatelink.queue.core.windows.net'
  'privatelink.file.core.windows.net'
  'privatelink.web.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.documents.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.gremlin.cosmos.azure.com'
  'privatelink.table.cosmos.azure.com'
  'privatelink.postgres.database.azure.com'
  'privatelink.mysql.database.azure.com'
  'privatelink.mariadb.database.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.azurewebsites.net'
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.service.signalr.net'
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.afs.azure.net'
  'privatelink.datafactory.azure.net'
  'privatelink.adf.azure.com'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink.dev.azuresynapse.net'
  'privatelink.azuresynapse.net'
  'privatelink.sql.azuresynapse.net'
  'privatelink.azurehealthcareapis.com'
  'privatelink.search.windows.net'
  'privatelink.azurecr.io'
  'privatelink.azconfig.io'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.servicebus.windows.net'
  'privatelink.azure-devices.net'
  'privatelink.eventgrid.azure.net'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.azurestaticapps.net'
]

// Create the private DNS zones using array iteration
// This loop creates all DNS zones specified in the privateDnsZones parameter
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in privateDnsZones: {
  name: zone // Each zone name from the array (e.g., 'privatelink.blob.core.windows.net')
  location: 'global' // Private DNS zones are global resources, not region-specific
  tags: tags // Apply consistent tagging across all zones
  properties: {} // No additional properties required for basic zone creation
}]

// Link private DNS zones to the hub VNet for centralized DNS resolution
// This ensures the hub can resolve private endpoint names to IP addresses
resource hubVnetDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in privateDnsZones: {
  name: '${privateDnsZone[i].name}/hub${linkNameSuffix}' // Format: zone-name/hub-link
  location: 'global' // DNS links are also global resources
  tags: tags
  properties: {
    registrationEnabled: false // Hub typically doesn't auto-register VM records
    virtualNetwork: {
      id: hubVnetId // Link to the central hub network
    }
  }
}]

// Link private DNS zones to each spoke VNet for distributed DNS resolution
// This creates a many-to-many relationship: each spoke gets linked to all DNS zones
resource spokeVnetDnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (spokeVnetId, i) in spokeVnetIds: {
  // Create a link name that includes the spoke index and zone
  // Note: This creates multiple links per spoke (one for each DNS zone)
  name: '${privateDnsZone[i % length(privateDnsZones)].name}/spoke-${i}${linkNameSuffix}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false // Spokes typically don't auto-register VM records either
    virtualNetwork: {
      id: spokeVnetId // Link to the specific spoke network
    }
  }
  dependsOn: [
    hubVnetDnsZoneLink // Ensure hub links are created first for proper ordering
  ]
}]

// Output the IDs of all created private DNS zones for downstream consumption
// This array output makes it easy for other modules to reference the zones
output privateDnsZoneIds array = [for (zone, i) in privateDnsZones: {
  name: zone // The zone name for easy identification
  id: privateDnsZone[i].id // The Azure resource ID for programmatic reference
}]
