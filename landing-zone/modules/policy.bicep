// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/policy.bicep
// Description: Creates a Policy Assignment at RG scope in the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param assignmentName     string  // e.g. "enforce-tag-policy"
param policyDefinitionId string  // e.g. "/subscriptions/.../providers/Microsoft.Authorization/policyDefinitions/<policyGuid>"
param policyParameters   object  // e.g. { "tagName": { "value": "CostCenter" } }

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: assignmentName
  properties: {
    displayName:       assignmentName
    policyDefinitionId: policyDefinitionId
    parameters:        policyParameters
  }
}

output policyAssignmentId string = policyAssignment.id
