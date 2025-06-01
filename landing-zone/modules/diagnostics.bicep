// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/diagnostics.bicep
// Description: Attaches Diagnostic Settings to a specified resource (e.g. VNet).
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param resourceId string  // e.g. the VNet ID from networkModule.outputs.vnetId
param workspaceId string // e.g. your Log Analytics workspace resource ID

resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'resourceDiagnostics'
  // We set the scope to the actual resource by ID:
  scope: resourceId(resourceId)
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
