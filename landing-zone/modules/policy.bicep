// ───────────────────────────────────────────────────────────────────────────────────
// Azure Landing Zone Policy Assignment Module
// ───────────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-09 20:17:15
// Current User's Login: GEP-V

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
param policyDescription string = 'Policy Assignment created through Bicep'

@description('Enforcement mode for the policy. Default is Default (enforced)')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Non-compliance message for the policy')
param nonComplianceMessage string = 'Resource is not compliant with the assigned policy.'

@description('Metadata for the policy assignment')
param metadata object = {
  version: '1.0.0'
  category: 'Landing Zone Governance'
  createdBy: 'GEP-V'
  createdOn: '2025-06-09'
}

@description('Whether to use a managed identity for the policy assignment (required for DeployIfNotExists policies)')
param useIdentity bool = false

@description('Location for the policy assignment when using managed identity')
param location string = resourceGroup().location

// ───────────────────────────────────────────────────────────────────────────────────
// VARIABLES
// ───────────────────────────────────────────────────────────────────────────────────

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
    description: policyDescription
    policyDefinitionId: policyDefinitionId
    parameters: policyParameters
    enforcementMode: enforcementMode // Changed from integer to string
    nonComplianceMessages: [
      nonComplianceMessageObject
    ]
    metadata: metadata
  }
  identity: useIdentity ? {
    type: 'SystemAssigned'
  } : null
  // Removed tags property as it's not valid for this resource type
}

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
output enforcementMode string = enforcementMode // Changed from integer to string

@description('Resource group scope of the policy assignment')
output scope string = resourceGroup().id
