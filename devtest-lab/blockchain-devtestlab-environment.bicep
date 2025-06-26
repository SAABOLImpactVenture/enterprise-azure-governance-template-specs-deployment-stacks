//
// devtest-lab/blockchain-devtestlab-environment.bicep
//

/*
  DevTest Lab Bicep template for an IBFT Hyperledger Besu network
  - 4 Validator VMs
  - 2 RPC/API VMs
  - 2 Bootnodes (1 private, 1 public)
  - CustomScript artifact to install Besu
  - Auto-shutdown at 19:00 daily
*/

// PARAMETERS

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

@description('URI to the genesis.json file')
param genesisUri     string

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

@description('Enable HTTP RPC on the RPC nodes')
param rpcEnabled     bool   = false


// DERIVED VARIABLES

var keyVaultId = resourceId('Microsoft.KeyVault/vaults', keyVaultName)
var labId      = resourceId(labRg, 'Microsoft.DevTestLab/labs', labName)


// CUSTOM SCRIPT ARTIFACT

resource installBesuArtifact 'Microsoft.DevTestLab/labs/artifacts@2018-09-15' = {
  name: '${labName}/install-besu'
  parent: {
    id: labId
  }
  properties: {
    displayName:  'Install Besu (v25+)'
    artifactType: 'CustomScript'
    uri:           genesisUri  // reused param to point at your script URI instead if needed
    parameters: {
      GENESIS_URI: { type: 'String';  defaultValue: genesisUri }
      CHAIN_ID:    { type: 'String';  defaultValue: chainId }
      GAS_LIMIT:   { type: 'String';  defaultValue: gasLimit }
      BOOTNODES:   { type: 'String';  defaultValue: bootnodes }
      RPC_ENABLED: { type: 'Boolean'; defaultValue: rpcEnabled }
    }
  }
}


// FORMULAS: Validator, RPC, Bootnode

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
            artifactId: installBesuArtifact.id
            parameters: {
              GENESIS_URI: { value: genesisUri }
              CHAIN_ID:    { value: chainId }
              GAS_LIMIT:   { value: gasLimit }
              BOOTNODES:   { value: bootnodes }
              RPC_ENABLED: { value: false }
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
            artifactId: installBesuArtifact.id
            parameters: {
              GENESIS_URI: { value: genesisUri }
              CHAIN_ID:    { value: chainId }
              GAS_LIMIT:   { value: gasLimit }
              BOOTNODES:   { value: bootnodes }
              RPC_ENABLED: { value: rpcEnabled }
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
            artifactId: installBesuArtifact.id
            parameters: {
              GENESIS_URI:    { value: genesisUri }
              CHAIN_ID:       { value: chainId }
              GAS_LIMIT:      { value: gasLimit }
              BOOTNODES:      { value: bootnodes }
              RPC_ENABLED:    { value: false }
              bootnodeMode:   { value: true }
              staticPublicIp: { value: i == bootnodeCount }
            }
          }
        ]
      }
    }
  }
]


// DEVTEST LAB ENVIRONMENT

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
        name:      'validator-${i}'
        formulaId: validatorFormulas[i-1].id
        computeVm: { size: vmSize }
      }],
      [for i in range(1, rpcCount + 1): {
        name:      'rpc-${i}'
        formulaId: rpcFormulas[i-1].id
        computeVm: { size: vmSize }
      }],
      [for i in range(1, bootnodeCount + 1): {
        name:      'bootnode-${i}'
        formulaId: bootnodeFormulas[i-1].id
        computeVm: { size: vmSize }
      }]
    )
  }
}


// OUTPUTS

output rpc1PublicFqdn string = reference(resourceId(labRg, 'Microsoft.Network/publicIPAddresses', '${labName}-rpc-1-pip')).dnsSettings.fqdn
output rpc1PrivateIp string = reference(resourceId(labRg, 'Microsoft.Network/networkInterfaces', '${labName}-rpc-1-nic')).ipConfigurations[0].properties.privateIPAddress
