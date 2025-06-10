// =============================================================================
// Azure Policy Assignment Module
// Last Updated: 2025-06-10 12:50:16
// Author: GEP-V
// =============================================================================

@description('Name for the policy assignment')
param assignmentName string

@description('Policy definition ID to assign')
param policyDefinitionId string

@description('Description for the policy assignment')
param policyDescription string

@description('Display name for the policy assignment')
param displayName string

@description('Policy parameters as a JSON object')
param policyParameters object = {}

@description('Enforcement mode for the policy assignment')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Whether to use a managed identity for the policy assignment')
param useIdentity bool = false

// Create policy assignment resource
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  properties: {
    policyDefinitionId: policyDefinitionId
    displayName: displayName
    description: policyDescription
    parameters: policyParameters
    enforcementMode: enforcementMode
  }
  identity: useIdentity ? {
    type: 'SystemAssigned'
  } : null
}

// Output the ID of the created policy assignment
output policyAssignmentId string = policyAssignment.id
output policyParameters object = policyAssignment.properties.parameters
