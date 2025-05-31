// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/roleAssignment.bicep
// Description: Creates a Role Assignment from JSON parameters.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param roleAssignmentName string  // e.g. "landingZone-ReaderAssignment"
param principalId        string  // e.g. AAD Object ID of a user/service principal
param roleDefinitionId   string  // e.g. "/subscriptions/…/providers/Microsoft.Authorization/roleDefinitions/{roleGuid}"
param assignmentScope    string  // e.g. "/subscriptions/…/resourceGroups/landingZone-RG"

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name:   roleAssignmentName
  scope:  assignmentScope
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId:      principalId
  }
}

output roleAssignmentId string = roleAssignment.id
