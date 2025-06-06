// ───────────────────────────────────────────────────────────────────────────────────
// Azure Landing Zone Role Assignment Module
// ───────────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-06 20:02:40
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting RBAC role assignments from AI assistants, consider the following
// best practices to get optimal results:
//
// 1. Be specific about the security principle:
//    - "Assign this role to a service principal with ID..."
//    - "Assign Contributor role to this user's Object ID..."
//
// 2. Reference specific built-in roles by name:
//    - "Use the Reader built-in role"
//    - "Assign Storage Blob Data Contributor role"
//
// 3. Specify the exact scope needed:
//    - "Assign at resource group level"
//    - "Assign at subscription level"
//    - "Assign only to this specific resource"
//
// 4. Define role assignment naming strategy:
//    - "Use GUID for assignment name"
//    - "Use deterministic naming like 'sp-{principalName}-reader-assignment'"
// ───────────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// ───────────────────────────────────────────────────────────────────────────────────
// PARAMETERS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Name of the role assignment - typically a GUID')
param roleAssignmentName string

@description('AAD object ID of the principal being assigned the role')
@minLength(36)
@maxLength(36)
param principalId string

@description('Full resource ID of the role definition being assigned')
@minLength(1)
param roleDefinitionId string

@description('Type of principal receiving the role assignment')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

@description('Description of the role assignment')
param description string = ''

@description('Optional condition for the role assignment (preview feature)')
param condition string = ''

@description('Optional condition version for role assignment condition')
@allowed([
  '2.0'
])
param conditionVersion string = '2.0'

// ───────────────────────────────────────────────────────────────────────────────────
// VARIABLES
// ───────────────────────────────────────────────────────────────────────────────────

// Helper variables for common built-in roles
// These aren't used directly but provide reference for role GUIDs
var builtInRoles = {
  owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  userAccessAdmin: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  networkContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  storageAccountContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab')
  storageBlobDataContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  keyVaultAdministrator: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
  // Add more as needed
}

// Final condition properties
var conditionProperties = !empty(condition) ? {
  condition: condition
  conditionVersion: conditionVersion
} : {}

// ───────────────────────────────────────────────────────────────────────────────────
// RESOURCES
// ───────────────────────────────────────────────────────────────────────────────────

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: union({
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: principalType
    description: description
  }, conditionProperties)
}

// ───────────────────────────────────────────────────────────────────────────────────
// OUTPUTS
// ───────────────────────────────────────────────────────────────────────────────────

@description('Resource ID of the role assignment')
output roleAssignmentId string = roleAssignment.id

@description('Name of the role assignment')
output roleAssignmentName string = roleAssignment.name

@description('Principal ID assigned the role')
output principalId string = principalId

@description('Role definition ID that was assigned')
output roleDefinitionId string = roleDefinitionId

@description('Scope of the role assignment (resource group ID)')
output scope string = resourceGroup().id

/*
RBAC BEST PRACTICES:

1. Follow Principle of Least Privilege:
   - Assign the most restrictive role that still allows required operations
   - Prefer specific built-in roles over Contributor/Owner
   - Use custom roles only when built-in roles are insufficient

2. Security Guidelines:
   - Avoid assigning roles directly to users; prefer using groups
   - For service principals, use managed identities when possible
   - Implement regular access reviews for role assignments
   - Document purpose of each assignment for governance

3. Naming and Organization:
   - Use descriptive names or GUIDs for role assignments
   - Include description property to document purpose
   - Group related assignments in logical deployment units

4. Technical Implementation:
   - Use deterministic role assignment IDs to avoid duplication
   - Be aware that role assignments may take time to propagate
   - Consider PIM (Privileged Identity Management) for sensitive roles

USAGE EXAMPLES:

1. Assign Contributor to a service principal:
