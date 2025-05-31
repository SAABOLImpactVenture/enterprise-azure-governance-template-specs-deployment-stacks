# Replace with actual values from parameters
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "Dev_Test_Lab-demosmartcontract-vm-017910"
$vmName = "demosmartcontract-vm"
$location = "eastus"

# Login and set context
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Enable JIT
$jitPolicy = @{
  location = $location
  properties = @{
    virtualMachines = @(
      @{
        id = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$vmName"
        ports = @(
          @{
            number = 22
            protocol = "Any"
            allowedSourceAddressPrefix = "*"
            maxRequestAccessDuration = "PT1H"
          }
        )
      }
    )
  }
}

# Create JIT policy
Set-AzJitNetworkAccessPolicy -ResourceGroupName $resourceGroupName `
  -Name "$vmName-jit" `
  -Location $location `
  -VirtualMachine @($jitPolicy.properties.virtualMachines)

Write-Host "JIT access enabled for VM: $vmName"
