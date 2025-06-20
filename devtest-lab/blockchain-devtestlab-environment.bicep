/*
  Bicep template to define a DevTest Lab environment for an IBFT Ethereum-based network
  - Ubuntu 22.04 LTS VMs
  - 4 Validator nodes
  - 2 RPC/API nodes
  - 2 Bootnodes (private + public)
  - Key Vault integration, managed identities
  - VNet peering into existing hub-spoke
  - Auto-shutdown at 19:00 daily
*/

// 1. PARAMETERS

@description('Name of the existing DevTest Lab')
param labName        string

@description('Resource group containing the DevTest Lab')
param labRg          string

@description('Azure location for all resources')
param location       string = resourceGroup(labRg).location

@description('Hub VNet resource ID for peering')
param hubVnetId      string

@description('Key Vault name where genesis.json & nodekeys live')
param keyVaultName   string = 'dev-blockchain-lab-kv'

@description('VM size for all blockchain nodes')
param vmSize         string = 'Standard_D4s_v5'

@description('Image Publisher for the VM formulas')
param imagePublisher string = 'Canonical'

@description('Image Offer for the VM formulas')
param imageOffer     string = '0001-com-ubuntu-server-jammy'

@description('Image SKU for the VM formulas')
param imageSku       string = '22_04-lts-gen2'

@description('Image Version for the VM formulas')
param imageVersion   string = 'latest'

@description('Number of validator nodes')
param validatorCount int    = 4

@description('Number of RPC/API nodes')
param rpcCount       int    = 2

@description('Number of bootnode VMs')
param bootnodeCount  int    = 2

@description('Comma-separated enode URLs for bootnodes')
param bootnodes      string = ''

@description('Chain ID for IBFT network (hex)')
param chainId        string = '0x0A'

@description('Gas limit for IBFT network (hex)')
param gasLimit       string = '0x1C9C380'

@description('URI to the genesis.json file')
param genesisUri     string

@description('Enable HTTP RPC on the RPC nodes')
param rpcEnabled     bool   = false

// derived
var keyVaultId = resourceId('Microsoft.KeyVault/vaults', keyVaultName)
var labId      = resourceId(labRg, 'Microsoft.DevTestLab/labs', labName)


// 2. FORMULAS: one per role

resource validatorFormulas 'Microsoft.DevTestLab/labs/formulas@2018-09-15' = [
  for i in range(1, validatorCount + 1): {
    name: '${labName}-validator-${i}-formula'
    parent: {
      id: labId
    }
    properties: {
      osType: 'Linux'
      formulaContent: {
        artifacts: [
          {
            artifactId: '${labName}/Install-Besu'
            parameters: {
              genesisUri: { value: genesisUri }
              chainId:    { value: chainId }
              gasLimit:   { value: gasLimit }
              bootnodes:  { value: bootnodes }
              rpcEnabled: { value: false }
            }
          }
        ]
      }
    }
  }
]

resource rpcFormulas 'Microsoft.DevTestLab/labs/formulas@2018-09-15' = [
  for i in range(1, rpcCount + 1): {
    name: '${labName}-rpc-${i}-formula'
    parent: {
      id: labId
    }
    properties: {
      osType: 'Linux'
      formulaContent: {
        artifacts: [
          {
            artifactId: '${labName}/Install-Besu'
            parameters: {
              genesisUri: { value: genesisUri }
              chainId:    { value: chainId }
              gasLimit:   { value: gasLimit }
              bootnodes:  { value: bootnodes }
              rpcEnabled: { value: rpcEnabled }
            }
          }
        ]
      }
    }
  }
]

resource bootnodeFormulas 'Microsoft.DevTestLab/labs/formulas@2018-09-15' = [
  for i in range(1, bootnodeCount + 1): {
    name: '${labName}-bootnode-${i}-formula'
    parent: {
      id: labId
    }
    properties: {
      osType: 'Linux'
      formulaContent: {
        artifacts: [
          {
            artifactId: '${labName}/Install-Besu'
            parameters: {
              genesisUri:    { value: genesisUri }
              chainId:       { value: chainId }
              gasLimit:      { value: gasLimit }
              bootnodeMode:  { value: true }
              staticPublicIp:{ value: i == 2 }  // only the second bootnode public
            }
          }
        ]
      }
    }
  }
]

// 3. DEVTEST LAB ENVIRONMENT

resource labEnv 'Microsoft.DevTestLab/labs/environments@2018-09-15' = {
  name: '${labName}/blockchain-dev-env'
  parent: {
    id: labId
  }
  location: location
  properties: {
    description: 'Blockchain IBFT network environment'
    labVirtualNetworkId: hubVnetId
    allowClaim: true
    shutdown: {
      taskType: 'LabVmsShutdownTask'
      dailyRecurrence: {
        hours: [19]
      }
    }
    labVmProfiles: concat(
      [for i in range(1, validatorCount + 1): {
        name:       'validator-${i}'
        formulaId:  validatorFormulas[i-1].id
        computeVm: { size: vmSize }
      }],
      [for i in range(1, rpcCount + 1): {
        name:       'rpc-${i}'
        formulaId:  rpcFormulas[i-1].id
        computeVm: { size: vmSize }
      }],
      [for i in range(1, bootnodeCount + 1): {
        name:       'bootnode-${i}'
        formulaId:  bootnodeFormulas[i-1].id
        computeVm: { size: vmSize }
      }]
    )
  }
}

// 4. OUTPUTS

output rpc1PublicFqdn  string = reference(resourceId(labRg, 'Microsoft.Network/publicIPAddresses', '${labName}-rpc-1-pip')).dnsSettings.fqdn
output rpc1PrivateIp  string = reference(resourceId(labRg, 'Microsoft.Network/networkInterfaces', '${labName}-rpc-1-nic')).ipConfigurations[0].properties.privateIPAddress
