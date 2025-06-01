// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/jit-access.bicep
// Description: Enables Just-In-Time (JIT) Access for a VM in the current RG.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters from the orchestrator
param vmName   string
param location string

resource jitPolicy 'Microsoft.Security/justInTimeNetworkAccessPolicies@2022-01-01-preview' = {
  name:     vmName   // the JIT policy is named after the VM
  location: location
  properties: {
    virtualMachines: [
      {
        id: resourceId('Microsoft.Compute/virtualMachines', vmName)
        ports: [
          {
            numberOfPorts: 1
            port:          22
            protocol:      '*'
            allowedSourceAddressPrefix: '*'
            maxRequestAccessDuration:    'PT3H' // allow up to 3 hours
          }
        ]
      }
    ]
  }
}

output jitPolicyId string = jitPolicy.id
