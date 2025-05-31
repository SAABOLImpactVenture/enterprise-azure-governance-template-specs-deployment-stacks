param labName string
param vmName string
param dnsName string
param sshPublicKey string
param labVirtualNetworkId string

resource labVm 'Microsoft.DevTestLab/labs/virtualmachines@2018-09-15' = {
  name: '${labName}/${vmName}'
  location: resourceGroup().location
  properties: {
    labVirtualNetworkId: labVirtualNetworkId
    notes: 'Smart Contract Demo VM'
    osType: 'Linux'
    size: 'Standard_B1s'
    userName: 'azureuser'
    sshKey: {
      keyData: sshPublicKey
    }
    allowClaim: false
    disallowPublicIpAddress: false
    artifacts: []
    storageType: 'Standard'
    imageReference: {
      offer: 'UbuntuServer'
      publisher: 'Canonical'
      sku: '20_04-lts-gen2'
      version: 'latest'
    }
  }
  tags: {
    environment: 'Dev'
    project: 'SmartContract'
  }
}
