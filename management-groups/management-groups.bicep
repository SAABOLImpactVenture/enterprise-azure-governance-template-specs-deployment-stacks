targetScope = 'tenant'

param rootName               string = 'Platform-MG'
param managementChildName    string = 'Management-MG'
param identityChildName      string = 'Identity-MG'
param connectivityChildName  string = 'Connectivity-MG'
param landingZonesChildName  string = 'Landing-Zones-MG'
param sandboxChildName       string = 'Sandbox-MG'

resource rootMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: rootName
  properties: {
    displayName: 'Platform Management Group'
    details: {}
  }
}

resource mgManagement 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: managementChildName
  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

resource mgIdentity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: identityChildName
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

resource mgConnectivity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: connectivityChildName
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

resource mgLandingZones 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: landingZonesChildName
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

resource mgSandbox 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: sandboxChildName
  properties: {
    displayName: 'Sandbox'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}
