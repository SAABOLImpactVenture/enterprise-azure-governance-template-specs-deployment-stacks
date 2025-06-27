targetScope = 'resourceGroup'

/*
  DevTest Lab Bicep template for an IBFT Hyperledger Besu network
  – 4 Validators, 2 RPC/API nodes, 2 Bootnodes
  – Registers a CustomScript artifact to install Besu
  – Auto-shutdown at 19:00 daily
*/

// PARAMETERS

@description('Name of the existing DevTest Lab')
param labName           string

@description('Azure region for all resources')
param location          string = resourceGroup().location

@description('URI to the install-besu.sh script')
param installScriptUri  string = 'https://raw.githubusercontent.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/main/devtest-lab/scripts/install-besu.sh'

@description('URI to the locked-down genesis.json')
param genesisUri        string = 'https://raw.githubusercontent.com/SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks/main/devtest-lab/genesis/genesis.json'

@description('IBFT Chain ID (hex or decimal)')
param chainId           string = '0x0A'

@description('IBFT Gas Limit (hex)')
param gasLimit          string = '0x1C9C380'

@description('Comma-separated enode URLs for bootnodes')
param bootnodes         string = ''

@description('Enable HTTP JSON-RPC on RPC nodes')
param rpcEnabled        bool   = false

@description('Size for all VMs')
param vmSize            string = 'Standard_D4s_v5'

@description('Number of validator VMs')
param validatorCount    int    = 4

@description('Number of RPC/API VMs')
param rpcCount          int    = 2

@description('Number of bootnode VMs')
param bootnodeCount     int    = 2

@description('ID of the existing virtual network to peer into')
param labVnetId         string


// DERIVED

var labId = resourceId('Microsoft.DevTestLab/labs', labName)


// 1) REGISTER THE CUSTOMSCRIPT ARTIFACT

resource installBesuArtifact 'Microsoft.DevTestLab/labs/artifacts@2018-09-15' = {
  name: '${labName}/install-besu'
  parent: { id: labId }
  properties: {
    displayName:  'Install Besu (v25+)'
    artifactType: 'CustomScript'
    uri:           installScriptUri
    parameters: {
      GENESIS_URI: { type: 'String';  defaultValue: genesisUri }
      CHAIN_ID:    { type: 'String';  defaultValue: chainId }
      GAS_LIMIT:   { type: 'String';  defaultValue: gasLimit }
      BOOTNODES:   { type: 'String';  defaultValue: bootnodes }
      RPC_ENABLED: { type: 'Boolean'; defaultValue: rpcEnabled }
    }
  }
}


// 2) FORMULAS FOR EACH ROLE

resource validatorFormulas 'Microsoft.DevTestLab/labs/formulas@2018-09-15' = [
  for i in range(1, validatorCount + 1): {
    name: '${labName}-validator-${i}-formula'
    parent: { id: labId }
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
    parent: { id: labId }
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
    parent: { id: labId }
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


// 3) PROVISION THE DEVTEST LAB ENVIRONMENT

resource labEnv 'Microsoft.DevTestLab/labs/environments@2018-09-15' = {
  name: '${labName}/blockchain-dev-env'
  parent: { id: labId }
  location: location
  properties: {
    description:         'IBFT Besu network environment'
    labVirtualNetworkId: labVnetId
    allowClaim:          true
    shutdown: {
      taskType:    'LabVmsShutdownTask'
      dailyRecurrence: {
        hours: [19]
      }
    }
    labVmProfiles: concat(
      [
        for i in range(1, validatorCount + 1): {
          name:      'validator-${i}'
          formulaId: validatorFormulas[i-1].id
          computeVm: { size: vmSize }
        }
      ],
      [
        for i in range(1, rpcCount + 1): {
          name:      'rpc-${i}'
          formulaId: rpcFormulas[i-1].id
          computeVm: { size: vmSize }
        }
      ],
      [
        for i in range(1, bootnodeCount + 1): {
          name:      'bootnode-${i}'
          formulaId: bootnodeFormulas[i-1].id
          computeVm: { size: vmSize }
        }
      ]
    )
  }
}


// 4) OPTIONAL OUTPUTS

output rpc1Fqdn    string = reference(resourceId('Microsoft.Network/publicIPAddresses', '${labName}-rpc-1-pip')).dnsSettings.fqdn
output rpc1Private string = reference(resourceId('Microsoft.Network/networkInterfaces',    '${labName}-rpc-1-nic')).ipConfigurations[0].properties.privateIPAddress
