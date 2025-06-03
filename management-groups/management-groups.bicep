// =================================================================================
// File: management-groups/management-groups.bicep
// Purpose: Create a “Platform-MG” root and five child MGs under it. Deploy at tenant scope.
// =================================================================================

// Name of the root management group
param rootName string = 'Platform-MG'

// Child management group names (you can change these if you want different names)
param managementChildName     string = 'Management-MG'
param identityChildName       string = 'Identity-MG'
param connectivityChildName   string = 'Connectivity-MG'
param landingZonesChildName   string = 'Landing-Zones-MG'
param sandboxChildName        string = 'Sandbox-MG'

// Create the root MG: Platform-MG
resource rootMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: rootName
  properties: {
    displayName: 'Platform Management Group'
    // No parent: this becomes a new root under the tenant.
  }
}

// Create Management-MG under Platform-MG
resource mgManagement 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: managementChildName
  properties: {
    displayName: 'Management'
    parent: {
      id: rootMG.id
    }
  }
}

// Create Identity-MG under Platform-MG
resource mgIdentity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: identityChildName
  properties: {
    displayName: 'Identity'
    parent: {
      id: rootMG.id
    }
  }
}

// Create Connectivity-MG under Platform-MG
resource mgConnectivity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: connectivityChildName
  properties: {
    displayName: 'Connectivity'
    parent: {
      id: rootMG.id
    }
  }
}

// Create Landing-Zones-MG under Platform-MG
resource mgLandingZones 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: landingZonesChildName
  properties: {
    displayName: 'Landing Zones'
    parent: {
      id: rootMG.id
    }
  }
}

// Create Sandbox-MG under Platform-MG
resource mgSandbox 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: sandboxChildName
  properties: {
    displayName: 'Sandbox'
    parent: {
      id: rootMG.id
    }
  }
}
