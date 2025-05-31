# Variables (Update these before running)
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "<your-resource-group>"
$vmName = "<your-vm-name>"
$location = "eastus"

# Login and set subscription
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Construct the JIT policy configuration
$jitPolicy = @{
    Location = $location
    Name = $vmName
    Kind = "Basic"
    Properties = @{
        VirtualMachines = @(
            @{
                Id = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$vmName"
                Ports = @(
                    @{
                        Number = 22
                        Protocol = "*"
                        AllowedSourceAddressPrefix = "xxx.xxx.xxx.xxx/32" # Replace with your IP or CIDR range
                        MaxRequestAccessDuration = "PT3H"
                    }
                )
            }
        )
    }
}

# Register JIT Network Access Policy
New-AzJitNetworkAccessPolicy @jitPolicy
