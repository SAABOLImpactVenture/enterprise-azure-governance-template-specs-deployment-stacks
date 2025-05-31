// ─────────────────────────────────────────────────────────────────────────────
// File: landing-zone/modules/jit-access.bicep
// Description: Enables Just‐In‐Time (JIT) VM Access on a specified VM.
// ─────────────────────────────────────────────────────────────────────────────

targetScope = 'resourceGroup'

// Parameters passed in from the orchestrator:
param vmName   string
param location string

// 1) Define a JIT policy for the VM. This example uses a simple JIT rule to allow
//    SSH (TCP 22) for up to 3 hours; adapt as needed.
resource jitPolicy 'Microsoft.Security/justInTimeNetworkAccessPolicies@2022-01-01-preview' = {
  name: vmName
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
            maxRequestAccessDuration:    'PT3H' // 3 hours
          }
        ]
      }
    ]
  }
}

output jitPolicyId string = jitPolicy.id
