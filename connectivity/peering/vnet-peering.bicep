// Target scope set to subscription level to allow cross-subscription peering operations
targetScope = 'subscription'

@description('Subscription ID where the source VNet lives')
param sourceSubscriptionId        string

@description('Resource group name of the source VNet')
param sourceResourceGroupName     string

@description('Name of the source Virtual Network')
param sourceVnetName              string

@description('Subscription ID of the destination VNet')
param destinationSubscriptionId   string

@description('Resource group name of the destination VNet')
param destinationResourceGroupName string

@description('Name of the destination Virtual Network')
param destinationVnetName         string

@description('Peering resource name to create under the source VNet')
param peeringName                 string

@description('Allow virtual network access on this peering')
param allowVirtualNetworkAccess   bool = true

@description('Allow forwarded traffic on this peering')
param allowForwardedTraffic       bool = true

@description('Allow gateway transit on this peering')
param allowGatewayTransit         bool = false

@description('Use remote gateways on this peering')
param useRemoteGateways           bool = false


// ■■ Reference the source VNet as an existing resource in its subscription/RG ■■
// This allows the template to operate on VNets across different subscriptions
resource sourceVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(sourceSubscriptionId, sourceResourceGroupName) // Cross-subscription scope
  name:  sourceVnetName
}

// ■■ Create the peering under that VNet ■■
// This creates a unidirectional peering from source to destination
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: sourceVnet // Parent relationship ensures proper resource hierarchy
  name:   peeringName
  properties: {
    remoteVirtualNetwork: {
      // Build the full resource ID for the destination VNet in a different subscription
      id: resourceId(
            destinationSubscriptionId,
            'Microsoft.Network/virtualNetworks',
            destinationResourceGroupName,
            destinationVnetName
        )
    }
    // Enable VM-to-VM communication across the peering
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    // Allow traffic forwarded by network virtual appliances (e.g., firewalls)
    allowForwardedTraffic:     allowForwardedTraffic
    // Allow this VNet's gateway to be used by the remote VNet (hub scenario)
    allowGatewayTransit:       allowGatewayTransit
    // Use the remote VNet's gateway for internet/on-premises traffic (spoke scenario)
    useRemoteGateways:         useRemoteGateways
  }
}

// Return the peering resource ID for confirmation and potential dependency chains
output peeringId string = vnetPeering.id
