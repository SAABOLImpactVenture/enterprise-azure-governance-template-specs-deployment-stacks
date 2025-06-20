// ─────────────────────────────────────────────────────────────────────────────
// File: landing‐zone/landing‐zone.bicep
// Description: Subscription‐scoped orchestrator that:
//   1) Creates or updates a Resource Group (rgName) in (location)
//   2) Invokes six resource‐group‐scoped modules (network, nsg, jit, diagnostics,
//      policy assignment, and role assignment) inside that RG.
//
// Because this creates a Resource Group from subscription scope, we declare:
//   targetScope = 'subscription'
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'subscription'

// ─────────────────────────────────────────────────────────────────────────────
// 1) Top‐level parameters (from landing‐zone/parameters/landing‐zone.parameters.json)
// ─────────────────────────────────────────────────────────────────────────────

// 1a) Subscription & Resource Group
param location string   // e.g. "eastus"
param rgName   string   // e.g. "landingZone-RG"

// 1b) Network module parameters
param vnetName      string  // e.g. "landingZone-vnet"
param addressPrefix string  // e.g. "10.0.0.0/16"
param subnetPrefix  string  // e.g. "10.0.1.0/24"

// 1c) NSG module parameters
param nsgName  string  // e.g. "landingZone-NSG"
param nsgRules array   // Array of NSG rule objects (see nsg.bicep for schema)

// 1d) JIT module parameters
param vmName string  // e.g. "landingZone-VM"

// 1e) Diagnostics module parameters
param diagnosticsWorkspaceId string  
// e.g. "/subscriptions/<subId>/resourceGroups/LogAnalytics-RG/providers/Microsoft.OperationalInsights/workspaces/MyLAWorkspace"

// 1f) (Optional) Load the policy assignment JSON from template‐specs/  
//     NOTE: path is "template-specs/policyAssignment.json" (not under "parameters/")
var policyAssignmentSpec = loadJsonContent('template-specs/policyAssignment.json')

// 1g) (Optional) Load the role assignment JSON from template‐specs/  
var roleAssignmentSpec = loadJsonContent('template-specs/roleAssignment.json')


// ─────────────────────────────────────────────────────────────────────────────
// 2) Resources
// ─────────────────────────────────────────────────────────────────────────────

// 2.1) Create (or update) the Resource Group named rgName
resource landingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:     rgName
  location: location
}

// 2.2) Invoke "network.bicep" inside landingRG (VNet + default subnet)
module networkModule 'modules/network.bicep' = {
  name:  'deployNetwork'
  scope: landingRG
  params: {
    vnetName:      vnetName
    addressPrefix: addressPrefix
    subnetPrefix:  subnetPrefix
    location:      location
  }
}

// 2.3) Invoke "nsg.bicep" inside landingRG (create NSG & associate to subnet)
module nsgModule 'modules/nsg.bicep' = {
  name:  'deployNSG'
  scope: landingRG
  params: {
    nsgName:    nsgName
    vnetName:   vnetName
    subnetName: 'default'
    nsgRules:      nsgRules // Pass the correct parameter name
    location:   location
  }
}

// 2.4) Invoke "jit-access.bicep" inside landingRG (enable JIT on VM)
module jitModule 'modules/jit-access.bicep' = {
  name:  'deployJIT'
  scope: landingRG
  params: {
    vmName:   vmName
    location: location
  }
}

// 2.5) Invoke "diagnostics.bicep" inside landingRG (attach diagnostics to VNet)
module diagnosticsModule 'modules/diagnostics.bicep' = {
  name:  'deployDiagnostics'
  scope: landingRG
  params: {
    vnetName:    vnetName
    workspaceId: diagnosticsWorkspaceId
  }
}

// 2.6) Invoke "policy.bicep" inside landingRG (create a Policy Assignment)
// Remove/comment this block if you do not have policyAssignment.json
module policyModule 'modules/policy.bicep' = {
  name:  'deployPolicy'
  scope: landingRG
  params: {
    assignmentName:     policyAssignmentSpec.name
    policyDefinitionId: policyAssignmentSpec.properties.policyDefinitionId
    policyParameters:   policyAssignmentSpec.properties.parameters
  }
}

// 2.7) Invoke "roleAssignment.bicep" inside landingRG (create a Role Assignment)
// Remove/comment this block if you do not have roleAssignment.json
module roleModule 'modules/roleAssignment.bicep' = {
  name:  'deployRole'
  scope: landingRG
  params: {
    roleAssignmentName: roleAssignmentSpec.name
    principalId:        roleAssignmentSpec.properties.principalId
    roleDefinitionId:   roleAssignmentSpec.properties.roleDefinitionId
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) Outputs (optional) – expose RG ID, VNet ID, Subnet ID
// ─────────────────────────────────────────────────────────────────────────────

output resourceGroupId string = landingRG.id
output vnetId         string = networkModule.outputs.vnetId
output subnetId       string = networkModule.outputs.subnetId
