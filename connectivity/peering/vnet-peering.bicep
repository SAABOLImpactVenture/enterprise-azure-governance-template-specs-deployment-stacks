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
resource sourceVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(sourceSubscriptionId, sourceResourceGroupName)
  name:  sourceVnetName
}

// ■■ Create the peering under that VNet ■■
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: sourceVnet
  name:   peeringName
  properties: {
    remoteVirtualNetwork: {
      id: resourceId(
            destinationSubscriptionId,
            'Microsoft.Network/virtualNetworks',
            destinationResourceGroupName,
            destinationVnetName
        )
    }
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic:     allowForwardedTraffic
    allowGatewayTransit:       allowGatewayTransit
    useRemoteGateways:         useRemoteGateways
  }
}

output peeringId string = vnetPeering.id
