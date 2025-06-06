<#
.SYNOPSIS
    Configures Network Security Group rules for Azure DevTest Lab VMs.
    
.DESCRIPTION
    This script configures a Network Security Group with hardened security rules,
    allowing SSH/RDP traffic only from specified IP ranges and blocking all other
    inbound traffic.
    
.PARAMETER VMName
    The name of the virtual machine to configure NSG for.
    
.PARAMETER ResourceGroup
    The resource group containing the VM and NSG.
    
.PARAMETER AllowedIpRange
    Optional. The IP range to allow for SSH/RDP access. Default is null (no restriction).
    
.PARAMETER SubscriptionId
    Optional. The Azure subscription ID. If not provided, uses the current context.
    
.EXAMPLE
    ./configure-nsg.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab"
    
.EXAMPLE
    ./configure-nsg.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab" -AllowedIpRange "203.0.113.0/24"
    
.NOTES
    Last Updated: 2025-06-06 19:50:50 UTC
    Current User's Login: GEP-V
    
    This script will:
    1. Connect to Azure (if not in a CI/CD context)
    2. Find the NSG associated with the specified VM
    3. Configure hardened security rules
    4. Allow SSH/RDP only from specified IP ranges
    5. Block all other inbound traffic
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [string]$AllowedIpRange = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null
)

# Script constants
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Write-Verbose "=== NSG Configuration Script Started ==="
Write-Verbose "Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Verbose "VM Name: $VMName"
Write-Verbose "Resource Group: $ResourceGroup"

try {
    # Check if running in Azure DevOps or GitHub Actions
    $isRunningInCI = $env:TF_BUILD -or $env:GITHUB_ACTIONS
    Write-Verbose "Running in CI/CD environment: $isRunningInCI"
    
    # Connect to Azure if not in CI context (CI uses managed identity or service principal)
    if (-not $isRunningInCI) {
        Write-Verbose "Connecting to Azure..."
        Connect-AzAccount -ErrorAction Stop
    }
    
    # Set subscription context if provided
    if ($SubscriptionId) {
        Write-Verbose "Setting subscription context to: $SubscriptionId"
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
    
    # Get the VM to find its network interfaces
    Write-Verbose "Getting VM details for $VMName..."
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction Stop
    
    if (-not $vm) {
        throw "VM '$VMName' not found in resource group '$ResourceGroup'."
    }
    
    # Get the VM's network interface
    $nicIds = $vm.NetworkProfile.NetworkInterfaces.Id
    if (-not $nicIds -or $nicIds.Count -eq 0) {
        throw "No network interfaces found for VM '$VMName'."
    }
    
    $primaryNicId = $nicIds[0]
    $nicName = $primaryNicId.Split('/')[-1]
    
    Write-Verbose "Getting network interface: $nicName"
    $nic = Get-AzNetworkInterface -ResourceId $primaryNicId -ErrorAction Stop
    
    # Get or create NSG
    $nsgId = $nic.NetworkSecurityGroup.Id
    $nsg = $null
    
    if ($nsgId) {
        $nsgName = $nsgId.Split('/')[-1]
        Write-Verbose "NSG found: $nsgName"
        $nsg = Get-AzNetworkSecurityGroup -ResourceId $nsgId -ErrorAction Stop
    } else {
        # Create a new NSG if none exists
        $nsgName = "$VMName-nsg"
        Write-Verbose "No NSG found. Creating new NSG: $nsgName"
        $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsgName -Location $vm.Location
        
        # Associate the NSG with the NIC
        $nic.NetworkSecurityGroup = New-Object Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup
        $nic.NetworkSecurityGroup.Id = $nsg.Id
        Set-AzNetworkInterface -NetworkInterface $nic | Out-Null
    }
    
    # Clear existing rules
    Write-Verbose "Clearing existing NSG rules..."
    $nsg.SecurityRules.Clear()
    
    # Add priority counter for rule ordering
    $priority = 100
    
    # Define the rules
    $rules = @()
    
    # Add SSH rule (only if IP range is specified)
    if ($AllowedIpRange) {
        Write-Verbose "Adding SSH rule for IP range: $AllowedIpRange"
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-SSH-From-Trusted-IPs" `
            -Description "Allow SSH from trusted IP range" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority $priority `
            -SourceAddressPrefix $AllowedIpRange `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 22
        
        $priority += 100
    } else {
        Write-Verbose "No IP restriction specified for SSH. Access will be allowed from any IP."
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" `
            -Description "Allow SSH access" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority $priority `
            -SourceAddressPrefix * `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 22
            
        $priority += 100
    }
    
    # Add RDP rule (only if IP range is specified)
    if ($AllowedIpRange) {
        Write-Verbose "Adding RDP rule for IP range: $AllowedIpRange"
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-RDP-From-Trusted-IPs" `
            -Description "Allow RDP from trusted IP range" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority $priority `
            -SourceAddressPrefix $AllowedIpRange `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 3389
            
        $priority += 100
    } else {
        Write-Verbose "No IP restriction specified for RDP. Access will be allowed from any IP."
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-RDP" `
            -Description "Allow RDP access" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority $priority `
            -SourceAddressPrefix * `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 3389
            
        $priority += 100
    }
    
    # Allow HTTPS for VM extensions and Azure services
    Write-Verbose "Adding rule to allow HTTPS for VM extensions"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-HTTPS" `
        -Description "Allow HTTPS for VM extensions and updates" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority $priority `
        -SourceAddressPrefix "VirtualNetwork" `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange 443
        
    $priority += 100
    
    # Allow Azure Load Balancer
    Write-Verbose "Adding rule to allow Azure Load Balancer"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-Azure-LB" `
        -Description "Allow Azure Load Balancer health probes" `
        -Access Allow `
        -Protocol * `
        -Direction Inbound `
        -Priority $priority `
        -SourceAddressPrefix "AzureLoadBalancer" `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange *
        
    $priority += 100
    
    # Deny All Inbound Traffic as the last rule
    Write-Verbose "Adding deny all inbound rule"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Deny-All-Inbound" `
        -Description "Deny all other inbound traffic" `
        -Access Deny `
        -Protocol * `
        -Direction Inbound `
        -Priority 4096 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange *
    
    # Add all rules to the NSG
    foreach ($rule in $rules) {
        Write-Verbose "Adding rule: $($rule.Name)"
        $nsg.SecurityRules.Add($rule)
    }
    
    # Update NSG with new rules
    Write-Verbose "Updating NSG with new rules..."
    $nsg = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    
    Write-Host "NSG '$($nsg.Name)' configured successfully with secure inbound rules." -ForegroundColor Green
    Write-Verbose "Rules configured: $($nsg.SecurityRules.Count)"

    # Validate rules were applied
    $appliedRules = (Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsg.Name).SecurityRules
    if ($appliedRules.Count -lt $rules.Count) {
        Write-Warning "Not all rules were applied successfully. Expected $($rules.Count), found $($appliedRules.Count)."
    }
    
    Write-Verbose "=== NSG Configuration Script Completed ==="
    return $true
} 
catch {
    Write-Error "An error occurred during NSG configuration: $_"
    Write-Error $_.Exception.StackTrace
    throw
}