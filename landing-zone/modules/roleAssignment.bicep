@description('The name of the Role Assignment. It must be a GUID.')
param roleAssignmentName string

@description('The scope at which the role assignment applies (e.g., a subscription, resource group, or resource).')
param scope string

@description('The role definition ID or built-in role definition ID (e.g., Reader, Contributor, Owner).')
param roleDefinitionId string

@description('The principal ID (Object ID) of the user, group, or service principal to assign the role to.')
param principalId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentName
  scope: scope
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal' // You can change to 'User' or 'Group' if needed
  }
}
