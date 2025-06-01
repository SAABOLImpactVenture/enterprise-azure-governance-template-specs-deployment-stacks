// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/diagnostics.bicep
// Description: Attaches Diagnostic Settings to an existing VNet inside this RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// 1) Parameters from orchestrator
param vnetName    string  // e.g. "landingZone-vnet"
param workspaceId string  // e.g. "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/MyLAWorkspace"

// 2) Reference the existing VNet by name (we do not need location here):
resource existingVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
}

// 3) Create (or update) diagnostic settings attached to that VNet
resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'vnetDiagnostics'
  scope: existingVnet
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled:  true
        retentionPolicy: {
          enabled: false
          days:    0
        }
      }
      {
        category: 'SubnetSecurityEvents'
        enabled:  true
        retentionPolicy: {
          enabled: false
          days:    0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled:  true
        retentionPolicy: {
          enabled: false
          days:    0
        }
      }
    ]
  }
}

output diagSettingsId string = diagSettings.id
