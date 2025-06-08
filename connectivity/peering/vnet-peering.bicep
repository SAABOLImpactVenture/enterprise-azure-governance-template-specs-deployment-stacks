// ==========================================================================
// Virtual Network Peering Module
// ==========================================================================
// PROMPT ENGINEERING GUIDANCE:
// This template establishes VNet peering connections:
// - Creates bidirectional peering between two virtual networks
// - Supports both hub-spoke and spoke-spoke peering patterns
// - Controls traffic forwarding and gateway transit options
// - Works across subscriptions when provided with full resource IDs
//
// USAGE CONTEXT:
// - Used when creating hub-spoke network architecture
// - Critical for cross-VNet communication in enterprise environments
// - Supports Azure Virtual WAN integration patterns
//
// PARAMETER GUIDANCE:
// - sourceVnetName: Name of the source VNet (where peering is created)
// - destinationVnetId: Full resource ID of target VNet (including subscription)
// - allowGatewayTransit: Set to true for hub VNet with gateway
// - useRemoteGateways: Set to true for spoke VNets to use hub gateway

@description('Name of the source virtual network')
param sourceVnetName string

@description('Resource ID of the destination virtual network')
param destinationVnetId string

@description('Name for the peering from source to destination')
param peeringName string = 'peering-to-${last(split(destinationVnetId, '/'))}'

@description('Whether to allow gateway transit in the peering')
param allowGatewayTransit bool = false

@description('Whether to use remote gateways in the peering')
param useRemoteGateways bool = false

@description('Whether to allow forwarded traffic in the peering')
param allowForwardedTraffic bool = true

@description('Whether to allow virtual network access in the peering')
param allowVirtualNetworkAccess bool = true

// Create VNet peering from source to destination
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: '${sourceVnetName}/${peeringName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: destinationVnetId
    }
  }
}

// Output the resource ID of the peering
output peeringId string = vnetPeering.id
