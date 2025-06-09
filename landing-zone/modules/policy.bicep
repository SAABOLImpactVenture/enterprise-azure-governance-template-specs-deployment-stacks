@description('Name of the policy assignment')
param assignmentName string

@description('Resource ID of the policy definition to assign')
param policyDefinitionId string

@description('Display name for the policy assignment')
param displayName string = assignmentName

@description('Description for the policy assignment')
param policyDescription string = 'Policy Assignment created through Bicep'

@description('Enforcement mode for the policy assignment')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Parameters for the policy assignment')
param policyParameters object

@description('Whether to use a managed identity for the policy assignment')
param useIdentity bool = false

@description('Location for the policy assignment')
param location string = resourceGroup().location

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  location: useIdentity ? location : null
  properties: {
    displayName: displayName
    description: policyDescription
    policyDefinitionId: policyDefinitionId
    parameters: policyParameters
    enforcementMode: enforcementMode
  }
  identity: useIdentity ? {
    type: 'SystemAssigned'
  } : null
}

output policyAssignmentId string = policyAssignment.id
output policyAssignmentName string = policyAssignment.name
output identityPrincipalId string = useIdentity ? policyAssignment.identity.principalId : ''
