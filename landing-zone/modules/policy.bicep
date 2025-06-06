// ───────────────────────────────────────────────────────────────────────────────────
// Azure Landing Zone Policy Assignment Module
// ───────────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-06 19:59:04
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting policy templates from AI assistants, consider the following
// best practices to get optimal results:
//
// 1. Be specific about the policy intent:
//    - "I need a policy to enforce resource tagging"
//    - "Create a policy to restrict VM sizes to these specific options..."
//
// 2. Specify the enforcement approach needed:
//    - Audit only vs. Deny vs. DeployIfNotExists
//    - Mention exemption requirements if any
//
// 3. Include details about remediation if needed:
//    - "The policy should use managed identity for automated remediation"
//    - "Include task creation for non-compliant resources"
//
// 4. Request specific parameter handling:
//    - "The allowed VM sizes should be parameterized"
//    - "Tag names and values should be configurable"
// ───────────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// ───────────────────────────────────────────────────────────────────────────────────
// PARAMETERS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Name of the policy assignment')
@minLength(3)
@maxLength(64)
param assignmentName string

@description('Resource ID of the policy definition to assign')
@minLength(10)
param policyDefinitionId string

@description('Parameters for the policy assignment')
param policyParameters object = {}

@description('Display name for the policy assignment')
param displayName string = assignmentName

@description('Description for the policy assignment')
param description string = 'Policy Assignment created through Bicep'

@description('Enforcement mode for the policy. Default is 1 (enforced)')
@allowed([
  'Default'   // 0
  'DoNotEnforce'  // 1
])
param enforcementMode string = 'Default'

@description('Non-compliance message for the policy')
param nonComplianceMessage string = 'Resource is not compliant with the assigned policy.'

@description('Metadata for the policy assignment')
param metadata object = {
  version: '1.0.0'
  category: 'Landing Zone Governance'
  createdBy: 'GEP-V'
  createdOn: '2025-06-06'
}

@description('Whether to use a managed identity for the policy assignment (required for DeployIfNotExists policies)')
param useIdentity bool = false

@description('Location for the policy assignment when using managed identity')
param location string = resourceGroup().location

@description('Tags to apply to the policy assignment')
param tags object = {}

// ───────────────────────────────────────────────────────────────────────────────────
// VARIABLES
// ───────────────────────────────────────────────────────────────────────────────────

// Convert enforcement mode string to integer value
var enforcementModeValue = enforcementMode == 'Default' ? 0 : 1

// Non-compliance message object
var nonComplianceMessageObject = {
  message: nonComplianceMessage
}

// ───────────────────────────────────────────────────────────────────────────────────
// RESOURCES
// ───────────────────────────────────────────────────────────────────────────────────

// Policy Assignment Resource
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  location: useIdentity ? location : null
  properties: {
    displayName: displayName
    description: description
    policyDefinitionId: policyDefinitionId
    parameters: policyParameters
    enforcementMode: enforcementModeValue
    nonComplianceMessages: [
      nonComplianceMessageObject
    ]
    metadata: metadata
  }
  identity: useIdentity ? {
    type: 'SystemAssigned'
  } : null
  tags: tags
}

// ───────────────────────────────────────────────────────────────────────────────────
// RBAC Assignment (for remediation if using managed identity)
// ───────────────────────────────────────────────────────────────────────────────────

// Use this role assignment if the policy uses DeployIfNotExists or Modify effects
// Typically this requires Contributor or more specific built-in/custom roles
// Note: To use this, uncomment and modify as needed
/*
resource policyRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (useIdentity) {
  name: guid(resourceGroup().id, policyAssignment.id, 'Contributor')
  properties: {
    principalId: policyAssignment.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalType: 'ServicePrincipal'
  }
}
*/

// ───────────────────────────────────────────────────────────────────────────────────
// OUTPUTS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Resource ID of the policy assignment')
output policyAssignmentId string = policyAssignment.id

@description('Name of the policy assignment')
output policyAssignmentName string = policyAssignment.name

@description('Principal ID of the managed identity, if enabled')
output identityPrincipalId string = useIdentity ? policyAssignment.identity.principalId : ''

@description('Enforcement mode of the policy assignment')
output enforcementMode int = enforcementModeValue

@description('Resource group scope of the policy assignment')
output scope string = resourceGroup().id

/*
POLICY CONSIDERATIONS:
1. When using DeployIfNotExists or Modify effects, enable managed identity (useIdentity=true)
2. For remediation tasks, the managed identity needs appropriate permissions (role assignments)
3. Consider starting with 'DoNotEnforce' mode to assess impact before enforcing
4. Use descriptive non-compliance messages to help users understand policy violations
5. Ensure policy parameters are properly validated in the policy definition

GOVERNANCE BEST PRACTICES:
1. Use policy initiatives (policy sets) for related policies instead of individual assignments
2. Apply policies at management group level when possible for broader scope
3. Plan exemptions for valid scenarios where policy should not apply
4. Include tags on policy assignments for better governance management
5. Document policy assignments in a central registry for visibility

PROMPT ENGINEERING TIP:
When troubleshooting policy issues with AI, specify:
- The exact non-compliance message shown
- The specific resources failing compliance
- Whether the policy uses Deny, Audit, or DeployIfNotExists effects
- Any exemptions that might apply
*/
