@description('Name of the resource to enable diagnostics on (e.g., VM or NSG)')
param targetResourceName string

@description('Resource type to enable diagnostics on (e.g., Microsoft.Network/networkSecurityGroups or Microsoft.Compute/virtualMachines)')
param targetResourceType string

@description('Resource ID of the Log Analytics Workspace')
param workspaceResourceId string

resource diagSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'enable-diagnostics-${targetResourceName}'
  scope: resource(targetResourceType, targetResourceName)
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Security'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
