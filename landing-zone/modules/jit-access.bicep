@description('The resource ID of the virtual machine to enable JIT on')
param vmResourceId string

resource securityInitiative 'Microsoft.Security/pricings@2022-03-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

resource jitPolicy 'Microsoft.Security/jitNetworkAccessPolicies@2015-06-01-preview' = {
  name: 'jitPolicy-${uniqueString(vmResourceId)}'
  location: 'centralus' // Use any valid region, JIT policy is global but must be declared in a region
  properties: {
    virtualMachines: [
      {
        id: vmResourceId
        ports: [
          {
            number: 22
            protocol: '*'
            allowedSourceAddressPrefix: 'Internet'
            maxRequestAccessDuration: 'PT3H'
          }
        ]
      }
    ]
  }
}
