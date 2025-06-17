// =============================================================================
// Azure Policy Assignment Module
// Last Updated: 2025-06-17 12:37:33
// Author: GEP-V
// =============================================================================
//
// PROMPT ENGINEERING NOTES:
// When using AI assistants to generate or modify Bicep modules for Azure Policy Assignment, follow these best practices:
//
// 1. Explicitly specify which parameters are required for automation and flexibility:
//    - assignmentName: Unique name for the policy assignment
//    - policyDefinitionId: Resource ID of the policy definition to assign
//    - policyDescription & displayName: Clear human-readable context for the assignment
//    - policyParameters: Use a JSON object for parameterizing the policy
//    - enforcementMode: Choose between 'Default' or 'DoNotEnforce' (parameterized)
//    - useIdentity: Optionally assign a managed identity to the policy assignment
//
// 2. Parameterize all configuration inputs to maximize reusability for different policies and scopes.
//
// 3. Use the @description and @allowed decorators to provide context and validation for each parameter.
//
// 4. Document the intended deployment scope (resource group, subscription, etc.) and reference best practices for Azure Policy management.
//
// 5. Output critical resource identifiers (e.g., policyAssignmentId) for downstream automation or reporting.
//
// 6. When asking AI to generate or review this module, request that policy assignment identity, enforcement mode, and parameter objects are always explicitly handled for enterprise compliance.
//
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
