@description('Name for the peering from hub to spoke')
param hubToSpokePeeringName string

@description('Name for the peering from spoke to hub')
param spokeToHubPeeringName string

@description('Resource ID of the hub virtual network')
param hubVnetId string

@description('Resource ID of the spoke virtual network')
param spokeVnetId string 

@description('Flag to control if spoke network can use hub\'s gateway')
param useRemoteGateways bool = false

@description('Flag to control if spoke network traffic can be forwarded through hub')
param allowForwardedTraffic bool = true

@description('Flag to allow gateway transit from hub to spokes')
param allowGatewayTransit bool = true

// Extract VNet names from resource IDs for easier peering naming
var hubVnetName = last(split(hubVnetId, '/'))
var spokeVnetName = last(split(spokeVnetId, '/'))
var hubVnetSubscriptionId = split(hubVnetId, '/')[2]
var hubVnetResourceGroupName = split(hubVnetId, '/')[4]
var spokeVnetSubscriptionId = split(spokeVnetId, '/')[2]
var spokeVnetResourceGroupName = split(spokeVnetId, '/')[4]

// Hub to Spoke peering
module hubToSpokePeering 'br/public:network/virtual-network-peering:1.0.2' = {
  name: 'hub-to-spoke-peering-${uniqueString(hubVnetId, spokeVnetId)}'
  scope: resourceGroup(hubVnetSubscriptionId, hubVnetResourceGroupName)
  params: {
    name: empty(hubToSpokePeeringName) ? 'peering-${hubVnetName}-to-${spokeVnetName}' : hubToSpokePeeringName
    localVnetName: hubVnetName
    remoteVnetId: spokeVnetId
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
}

// Spoke to Hub peering
module spokeToHubPeering 'br/public:network/virtual-network-peering:1.0.2' = {
  name: 'spoke-to-hub-peering-${uniqueString(hubVnetId, spokeVnetId)}'
  scope: resourceGroup(spokeVnetSubscriptionId, spokeVnetResourceGroupName)
  params: {
    name: empty(spokeToHubPeeringName) ? 'peering-${spokeVnetName}-to-${hubVnetName}' : spokeToHubPeeringName
    localVnetName: spokeVnetName
    remoteVnetId: hubVnetId
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: useRemoteGateways
  }
}

// Output the peering resource IDs
output hubToSpokePeeringId string = hubToSpokePeering.outputs.resourceId
output spokeToHubPeeringId string = spokeToHubPeering.outputs.resourceId
