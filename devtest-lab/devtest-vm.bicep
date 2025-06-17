// ─────────────────────────────────────────────────────────────────────────────
// DevTest Lab VM Deployment Module
// ─────────────────────────────────────────────────────────────────────────────
// Current Date and Time (UTC): 2025-06-17 12:30:41
// Current User's Login: GEP-V
//
// PROMPT ENGINEERING NOTES:
// When requesting DevTest Lab VM templates from AI assistants, consider the following best practices:
//
// 1. Specify required parameters for reproducibility and automation:
//    - labName: The name of the DevTest Lab
//    - vmName: The name of the virtual machine
//    - dnsName: The DNS label for the VM (if required by the scenario)
//    - sshPublicKey: Public key for secure SSH authentication
//    - labVirtualNetworkId: The resource ID of the lab's virtual network
//
// 2. Clarify the OS, VM size, and baseline image requirements:
//    - "Deploy an Ubuntu 20.04 LTS Linux VM with Standard_B1s size"
//    - "Use a marketplace image (specify offer, publisher, sku, version)"
//
// 3. Note additional configuration needs:
//    - "Disable public IP if VM should be internal only"
//    - "Preinstall artifacts or extensions if needed"
//    - "Set tags for environment and project context"
//
// 4. If using for smart contract or blockchain development/testing, specify the use case in the notes or tags.
//
// 5. For automation or pipelines, parameterize as many settings as possible for maximum reusability.
//
// ─────────────────────────────────────────────────────────────────────────────

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
