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

// Create the private DNS zones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in privateDnsZones: {
  name: zone
  location: 'global'
  tags: tags
  properties: {}
}]

// Link private DNS zones to the hub VNet
resource hubVnetDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in privateDnsZones: {
  name: '${privateDnsZone[i].name}/hub${linkNameSuffix}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}]

// Link private DNS zones to each spoke VNet
resource spokeVnetDnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (spokeVnetId, i) in spokeVnetIds: {
  name: '${privateDnsZone[i % length(privateDnsZones)].name}/spoke-${i}${linkNameSuffix}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
  dependsOn: [
    hubVnetDnsZoneLink
  ]
}]

// Output the IDs of all created private DNS zones
output privateDnsZoneIds array = [for (zone, i) in privateDnsZones: {
  name: zone
  id: privateDnsZone[i].id
}]
