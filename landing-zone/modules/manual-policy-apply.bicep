// This is a placeholder file that documents the direct Azure CLI approach
// Being used to work around ARM/Bicep parameter passing issues

/* 
MANUAL POLICY APPLICATION PROCESS

Since we're experiencing persistent issues with policy parameters through ARM/Bicep,
we're using direct Azure CLI commands to apply the policy:

az policy assignment create \
  --name "enforce-tag-policy" \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy "1e30110a-5ceb-460c-a204-c1c3969c6d62" \
  --params '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' \
  --scope "/subscriptions/{subscription-id}/resourceGroups/rg-management" \
  --enforcement-mode Default

This approach ensures both required parameters (tagName and tagValue) are properly passed.
*/

// This module doesn't deploy anything but serves as documentation
@description('Resource group for policy assignment')
param resourceGroupName string

@description('Policy definition ID')
param policyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62'

@description('Policy assignment name')
param policyName string = 'enforce-tag-policy'

output policyName string = policyName
output policyDefinitionId string = policyDefinitionId
output resourceGroup string = resourceGroupName
output note string = 'Policy is applied directly via Azure CLI script.'
