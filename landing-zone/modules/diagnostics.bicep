// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/diagnostics.bicep
// Description: Configures Diagnostic Settings on a given resource (e.g. a VNet).
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param resourceId string  // e.g. the VNet ID from networkModule.outputs.vnetId
param workspaceId string // e.g. Log Analytics workspace resource ID
param location    string // (optional, not strictly needed, but kept for parity)

// 1) Attach diagnostic settings to that resource
resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'resourceDiagnostics'
  scope: resource(resourceId)
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
