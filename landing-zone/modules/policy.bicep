// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/policy.bicep
// Description: Creates a Policy Assignment from JSON parameters.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param assignmentName      string
param assignmentScope     string   // e.g. "/subscriptions/…/resourceGroups/landingZone-RG"
param policyDefinitionId  string   // e.g. built-in or custom policy definition ID
param policyParameters    object   // JSON object for policy parameters

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name:       assignmentName
  scope:      assignmentScope
  properties: {
    displayName:       assignmentName
    policyDefinitionId: policyDefinitionId
    parameters:        policyParameters
  }
}

output policyAssignmentId string = policyAssignment.id
