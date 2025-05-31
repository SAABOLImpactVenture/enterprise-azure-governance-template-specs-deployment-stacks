# Replace with actual values
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "Dev_Test_Lab-demosmartcontract-vm-017910"
$nsgName = "demosmartcontract-nsg"   # Ensure this matches your actual NSG name
$allowedIpRange = "203.0.113.0/24"  # Replace with your trusted IP range

# Log in and set subscription context
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Get existing NSG (if it exists)
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName -ErrorAction SilentlyContinue

if (-not $nsg) {
    Write-Host "Network Security Group '$nsgName' not found in resource group '$resourceGroupName'."
    return
}

# Define SSH Rule (Allow SSH from a specific IP range)
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH-Specific-IP" `
    -Description "Allow SSH from specific IP range" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix $allowedIpRange `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

# Define Deny All Inbound Rule
$nsgRuleDenyAll = New-AzNetworkSecurityRuleConfig -Name "Deny-All-Inbound" `
    -Description "Deny all other inbound traffic" `
    -Access Deny `
    -Protocol * `
    -Direction Inbound `
    -Priority 4096 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange *

# Add rules to NSG
$nsg.SecurityRules.Clear()
$nsg.SecurityRules.Add($nsgRuleSSH)
$nsg.SecurityRules.Add($nsgRuleDenyAll)

# Update NSG
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

Write-Host "NSG '$nsgName' configured successfully with secure inbound rules."
