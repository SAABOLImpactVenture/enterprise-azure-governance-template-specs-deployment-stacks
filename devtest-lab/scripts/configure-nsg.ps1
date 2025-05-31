# Variables – replace these with your actual values
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "<your-resource-group>"
$nsgName = "<your-nsg-name>"
$allowedIpRange = "203.0.113.0/24"  # Replace with your trusted IP range

# Log in and set context
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Rule 1: Allow SSH (port 22) from a specific IP range
$nsgRuleSSH = @{
    Name                      = "Allow-SSH-Specific-IP"
    ResourceGroupName         = $resourceGroupName
    NetworkSecurityGroupName  = $nsgName
    Direction                 = "Inbound"
    Priority                  = 100
    Access                    = "Allow"
    Protocol                  = "Tcp"
    SourceAddressPrefix       = $allowedIpRange
    SourcePortRange           = "*"
    DestinationAddressPrefix  = "*"
    DestinationPortRange      = "22"
    Description               = "Allow SSH only from specific IP range"
}

New-AzNetworkSecurityRuleConfig @nsgRuleSSH

# Rule 2: Deny all other inbound traffic (optional hardening rule)
$nsgRuleDenyAll = @{
    Name                      = "Deny-All-Inbound"
    ResourceGroupName         = $resourceGroupName
    NetworkSecurityGroupName  = $nsgName
    Direction                 = "Inbound"
    Priority                  = 4096
    Access                    = "Deny"
    Protocol                  = "*"
    SourceAddressPrefix       = "*"
    SourcePortRange           = "*"
    DestinationAddressPrefix  = "*"
    DestinationPortRange      = "*"
    Description               = "Deny all other inbound traffic"
}

New-AzNetworkSecurityRuleConfig @nsgRuleDenyAll

# Apply changes to NSG
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName
$nsg.SecurityRules.Add((New-AzNetworkSecurityRuleConfig @nsgRuleSSH))
$nsg.SecurityRules.Add((New-AzNetworkSecurityRuleConfig @nsgRuleDenyAll))
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

Write-Host "NSG rules configured successfully."
