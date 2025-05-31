// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/landing-zone.bicep
// Description: Subscription‐scoped landing‐zone orchestrator that:
//   1) Creates or updates a Resource Group (rgName) in (location).
//   2) Invokes six resource‐group‐scoped modules (network, nsg, jit, diagnostics,
//      policy assignment, and role assignment) inside that RG.
//
// Because this file creates a Resource Group from subscription scope, we set:
//   targetScope = 'subscription'
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'subscription'

// ─────────────────────────────────────────────────────────────────────────────
// 1) Top‐level parameters (provided via landing-zone.parameters.json)
// ─────────────────────────────────────────────────────────────────────────────

// 1a) Subscription & Resource Group
param location string     // Azure region, e.g. “eastus”
param rgName   string     // Name of the RG to create, e.g. “landingZone-RG”

// 1b) Network module parameters
param vnetName      string    // VNet name, e.g. “landingZone-vnet”
param addressPrefix string    // VNet address space, e.g. “10.0.0.0/16”
param subnetPrefix  string    // Subnet prefix, e.g. “10.0.1.0/24”

// 1c) NSG module parameters
param nsgName string        // NSG resource name, e.g. “landingZone-NSG”
param nsgRules array       // Array of NSG rule objects (see nsg.bicep for shape)

// 1d) JIT module parameters
param vmName string         // VM name to enable just-in-time on, e.g. “landingZone-VM”

// 1e) Diagnostics module parameters
param diagnosticsWorkspaceId string
// e.g. "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/LogAnalytics-RG/providers/Microsoft.OperationalInsights/workspaces/MyLAWorkspace"

// 1f) Policy Assignment spec (load from JSON under parameters/template-specs)
var policyAssignmentSpec = loadJsonContent('parameters/template-specs/policyAssignment.json')

// 1g) Role Assignment spec (load from JSON under parameters/template-specs)
var roleAssignmentSpec = loadJsonContent('parameters/template-specs/roleAssignment.json')


// ─────────────────────────────────────────────────────────────────────────────
// 2) Resources
// ─────────────────────────────────────────────────────────────────────────────

// 2.1) Create (or update) the resource group named rgName
resource landingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:     rgName
  location: location
}

// 2.2) Deploy “network.bicep” inside landingRG (create VNet + default subnet)
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

// 2.3) Deploy “nsg.bicep” inside landingRG (create NSG & associate it to the subnet)
module nsgModule 'modules/nsg.bicep' = {
  name:  'deployNSG'
  scope: landingRG
  params: {
    nsgName:     nsgName
    vnetName:    vnetName
    subnetName:  'default'
    rules:       nsgRules
    location:    location
  }
}

// 2.4) Deploy “jit-access.bicep” inside landingRG (enable Just-In-Time access on VM)
module jitModule 'modules/jit-access.bicep' = {
  name:  'deployJIT'
  scope: landingRG
  params: {
    vmName:   vmName
    location: location
  }
}

// 2.5) Deploy “diagnostics.bicep” inside landingRG (attach diagnostic settings to the VNet)
module diagnosticsModule 'modules/diagnostics.bicep' = {
  name:  'deployDiagnostics'
  scope: landingRG
  params: {
    // Pass the ID of the VNet created by networkModule
    resourceId:          networkModule.outputs.vnetId
    workspaceId:         diagnosticsWorkspaceId
    location:            location
  }
}

// 2.6) Deploy “policy.bicep” inside landingRG (assign a policy)
module policyModule 'modules/policy.bicep' = {
  name:  'deployPolicy'
  scope: landingRG
  params: {
    assignmentName:       policyAssignmentSpec.name
    assignmentScope:      policyAssignmentSpec.properties.scope
    policyDefinitionId:   policyAssignmentSpec.properties.policyDefinitionId
    policyParameters:     policyAssignmentSpec.properties.parameters
  }
}

// 2.7) Deploy “roleAssignment.bicep” inside landingRG (assign a role)
module roleModule 'modules/roleAssignment.bicep' = {
  name:  'deployRole'
  scope: landingRG
  params: {
    roleAssignmentName:   roleAssignmentSpec.name
    principalId:          roleAssignmentSpec.properties.principalId
    roleDefinitionId:     roleAssignmentSpec.properties.roleDefinitionId
    assignmentScope:      roleAssignmentSpec.properties.scope
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) Outputs (optional) – expose RG ID, VNet ID, Subnet ID
// ─────────────────────────────────────────────────────────────────────────────

output resourceGroupId string = landingRG.id
output vnetId         string = networkModule.outputs.vnetId
output subnetId       string = networkModule.outputs.subnetId
