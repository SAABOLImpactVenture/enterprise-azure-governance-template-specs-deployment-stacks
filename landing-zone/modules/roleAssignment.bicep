// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/roleAssignment.bicep
// Description: Creates a Role Assignment at RG scope in the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param roleAssignmentName string  // e.g. a GUID or friendly name
param principalId       string  // e.g. "<AAD object ID of user/service principal>"
param roleDefinitionId  string  // e.g. "/subscriptions/.../providers/Microsoft.Authorization/roleDefinitions/<roleGuid>"

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentName
  properties: {
    principalId:      principalId
    roleDefinitionId: roleDefinitionId
  }
}

output roleAssignmentId string = roleAssignment.id
