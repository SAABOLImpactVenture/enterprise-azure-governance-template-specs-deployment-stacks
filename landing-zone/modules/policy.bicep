@description('Name of the policy definition')
param policyDefinitionName string

@description('Display name for the policy definition')
param displayName string

@description('Description of the policy definition')
param description string

@description('Policy rule definition as an object')
param policyRule object

@description('Policy parameters as an object')
@allowed([
  {}
])
param parameters object = {}

@description('The policy mode, such as "All", "Indexed", or "Microsoft.ContainerService.Data"')
@allowed([
  'All'
  'Indexed'
])
param policyMode string = 'All'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyDefinitionName
  properties: {
    displayName: displayName
    description: description
    mode: policyMode
    policyRule: policyRule
    parameters: parameters
  }
}
