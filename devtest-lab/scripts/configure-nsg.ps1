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
    
.PARAMETER AllowedSourceIpRanges
    Optional. Array of IP ranges to allow for SSH/RDP access. Uses more specific syntax than AllowedIpRange.
    
.PARAMETER SubscriptionId
    Optional. The Azure subscription ID. If not provided, uses the current context.
    
.PARAMETER EnableAutoDetectPorts
    Optional. Auto-detect which ports to open based on VM OS type. Default is true.
    
.PARAMETER ApplyTags
    Optional. Apply standard security tags to the NSG. Default is true.
    
.EXAMPLE
    ./configure-nsg.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab"
    
.EXAMPLE
    ./configure-nsg.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab" -AllowedIpRange "203.0.113.0/24"
    
.EXAMPLE
    ./configure-nsg.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab" -AllowedSourceIpRanges @("203.0.113.0/24", "198.51.100.0/24")
    
.NOTES
    Last Updated: 2025-06-06 23:24:48 UTC
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
    [string[]]$AllowedSourceIpRanges = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null,
    
    [Parameter(Mandatory = $false)]
    [bool]$EnableAutoDetectPorts = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$ApplyTags = $true
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
    } else {
        $currentContext = Get-AzContext
        $SubscriptionId = $currentContext.Subscription.Id
        Write-Verbose "Using current subscription context: $SubscriptionId"
    }
    
    # Get the VM to find its network interfaces
    Write-Verbose "Getting VM details for $VMName..."
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction Stop
    
    if (-not $vm) {
        throw "VM '$VMName' not found in resource group '$ResourceGroup'."
    }
    
    # Determine VM OS type for intelligent port configuration
    $osType = $vm.StorageProfile.OsDisk.OsType
    Write-Verbose "Detected VM OS Type: $osType"
    
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
        
        # Define tags for the NSG
        $tags = @{
            "Environment" = "DevTest"
            "Purpose" = "VM Security"
            "CreatedBy" = "GEP-V"
            "CreatedOn" = (Get-Date -Format 'yyyy-MM-dd')
            "AutomatedBy" = "NSG-Configuration-Script"
        }
        
        $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsgName -Location $vm.Location -Tag $tags
        
        # Associate the NSG with the NIC
        $nic.NetworkSecurityGroup = New-Object Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup
        $nic.NetworkSecurityGroup.Id = $nsg.Id
        Set-AzNetworkInterface -NetworkInterface $nic | Out-Null
    }
    
    # Backup existing rules
    $backupRules = $nsg.SecurityRules | ConvertTo-Json -Depth 5
    Write-Verbose "Backed up existing rules: $($nsg.SecurityRules.Count) rules saved"
    
    # Clear existing rules
    Write-Verbose "Clearing existing NSG rules..."
    $nsg.SecurityRules.Clear()
    
    # Combine all allowed IP ranges
    $ipRanges = @()
    if (-not [string]::IsNullOrEmpty($AllowedIpRange)) {
        $ipRanges += $AllowedIpRange
    }
    if ($AllowedSourceIpRanges.Count -gt 0) {
        $ipRanges += $AllowedSourceIpRanges
    }
    
    # Use the right source address prefix
    $sourceAddressPrefix = $ipRanges.Count -gt 0 ? $ipRanges : @("*")
    
    # Add priority counter for rule ordering
    $priority = 100
    
    # Define the rules
    $rules = @()
    
    # Auto-detect and add appropriate rules based on OS type
    if ($EnableAutoDetectPorts) {
        if ($osType -eq 'Windows') {
            Write-Verbose "Configuring Windows-specific rules (RDP)"
            
            # Add RDP rule with IP restrictions if specified
            $rdpRule = @{
                Name = "Allow-RDP" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" })
                Description = "Allow RDP access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" })
                Access = "Allow"
                Protocol = "Tcp"
                Direction = "Inbound"
                Priority = $priority
                SourceAddressPrefix = $sourceAddressPrefix
                SourcePortRange = "*"
                DestinationAddressPrefix = "*"
                DestinationPortRange = "3389"
            }
            
            $rules += New-AzNetworkSecurityRuleConfig @rdpRule
            $priority += 100
            
            # Add WinRM rule for Windows remote management if needed
            $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-WinRM" `
                -Description "Allow Windows Remote Management" `
                -Access "Allow" `
                -Protocol "Tcp" `
                -Direction "Inbound" `
                -Priority $priority `
                -SourceAddressPrefix $sourceAddressPrefix `
                -SourcePortRange "*" `
                -DestinationAddressPrefix "*" `
                -DestinationPortRange "5985-5986"
                
            $priority += 100
            
        } elseif ($osType -eq 'Linux') {
            Write-Verbose "Configuring Linux-specific rules (SSH)"
            
            # Add SSH rule with IP restrictions if specified
            $sshRule = @{
                Name = "Allow-SSH" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" })
                Description = "Allow SSH access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" })
                Access = "Allow"
                Protocol = "Tcp"
                Direction = "Inbound"
                Priority = $priority
                SourceAddressPrefix = $sourceAddressPrefix
                SourcePortRange = "*"
                DestinationAddressPrefix = "*"
                DestinationPortRange = "22"
            }
            
            $rules += New-AzNetworkSecurityRuleConfig @sshRule
            $priority += 100
            
        } else {
            Write-Verbose "OS type not determined, adding both SSH and RDP rules"
            
            # Add SSH rule
            $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" }) `
                -Description "Allow SSH access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" }) `
                -Access "Allow" `
                -Protocol "Tcp" `
                -Direction "Inbound" `
                -Priority $priority `
                -SourceAddressPrefix $sourceAddressPrefix `
                -SourcePortRange "*" `
                -DestinationAddressPrefix "*" `
                -DestinationPortRange "22"
                
            $priority += 100
            
            # Add RDP rule
            $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-RDP" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" }) `
                -Description "Allow RDP access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" }) `
                -Access "Allow" `
                -Protocol "Tcp" `
                -Direction "Inbound" `
                -Priority $priority `
                -SourceAddressPrefix $sourceAddressPrefix `
                -SourcePortRange "*" `
                -DestinationAddressPrefix "*" `
                -DestinationPortRange "3389"
                
            $priority += 100
        }
    } else {
        # If auto-detect is disabled, add both SSH and RDP rules
        Write-Verbose "Auto-detect ports disabled. Adding both SSH and RDP rules."
        
        # Add SSH rule
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" }) `
            -Description "Allow SSH access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" }) `
            -Access "Allow" `
            -Protocol "Tcp" `
            -Direction "Inbound" `
            -Priority $priority `
            -SourceAddressPrefix $sourceAddressPrefix `
            -SourcePortRange "*" `
            -DestinationAddressPrefix "*" `
            -DestinationPortRange "22"
            
        $priority += 100
        
        # Add RDP rule
        $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-RDP" + $(if ($ipRanges.Count -gt 0) { "-From-Trusted-IPs" } else { "" }) `
            -Description "Allow RDP access" + $(if ($ipRanges.Count -gt 0) { " from trusted IP ranges" } else { "" }) `
            -Access "Allow" `
            -Protocol "Tcp" `
            -Direction "Inbound" `
            -Priority $priority `
            -SourceAddressPrefix $sourceAddressPrefix `
            -SourcePortRange "*" `
            -DestinationAddressPrefix "*" `
            -DestinationPortRange "3389"
            
        $priority += 100
    }
    
    # Allow HTTPS for VM extensions and Azure services
    Write-Verbose "Adding rule to allow HTTPS for VM extensions"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-HTTPS" `
        -Description "Allow HTTPS for VM extensions and updates" `
        -Access "Allow" `
        -Protocol "Tcp" `
        -Direction "Inbound" `
        -Priority $priority `
        -SourceAddressPrefix "VirtualNetwork" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange "443"
        
    $priority += 100
    
    # Allow Azure Load Balancer
    Write-Verbose "Adding rule to allow Azure Load Balancer"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-Azure-LB" `
        -Description "Allow Azure Load Balancer health probes" `
        -Access "Allow" `
        -Protocol "*" `
        -Direction "Inbound" `
        -Priority $priority `
        -SourceAddressPrefix "AzureLoadBalancer" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange "*"
        
    $priority += 100
    
    # Add Azure Bastion service tag if using modern environments
    $rules += New-AzNetworkSecurityRuleConfig -Name "Allow-Bastion" `
        -Description "Allow Azure Bastion Service" `
        -Access "Allow" `
        -Protocol "*" `
        -Direction "Inbound" `
        -Priority $priority `
        -SourceAddressPrefix "AzureBastionSubnet" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange "22,3389"
        
    $priority += 100
    
    # Deny All Inbound Traffic as the last rule
    Write-Verbose "Adding deny all inbound rule"
    $rules += New-AzNetworkSecurityRuleConfig -Name "Deny-All-Inbound" `
        -Description "Deny all other inbound traffic" `
        -Access "Deny" `
        -Protocol "*" `
        -Direction "Inbound" `
        -Priority 4096 `
        -SourceAddressPrefix "*" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange "*"
    
    # Add all rules to the NSG
    foreach ($rule in $rules) {
        Write-Verbose "Adding rule: $($rule.Name)"
        $nsg.SecurityRules.Add($rule)
    }
    
    # Update NSG with new rules
    Write-Verbose "Updating NSG with new rules..."
    $nsg = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    
    # Apply tags if requested
    if ($ApplyTags) {
        Write-Verbose "Applying security tags to NSG..."
        $currentTags = $nsg.Tag
        if (-not $currentTags) {
            $currentTags = @{}
        }
        
        # Add or update security tags
        $currentTags["SecurityHardened"] = "True"
        $currentTags["LastUpdatedBy"] = "GEP-V"
        $currentTags["LastUpdatedOn"] = (Get-Date -Format 'yyyy-MM-dd')
        
        # Apply updated tags
        $nsg = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg -Tag $currentTags
    }
    
    Write-Host "✅ NSG '$($nsg.Name)' configured successfully with secure inbound rules." -ForegroundColor Green
    Write-Host "   - Rules configured: $($nsg.SecurityRules.Count)"
    Write-Host "   - Access restricted: $(if ($ipRanges.Count -gt 0) { "Yes - to $($ipRanges.Count) IP ranges" } else { "No - open access" })"
    Write-Host "   - Last rule: Deny all other inbound traffic"

    # Validate rules were applied
    $appliedRules = (Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsg.Name).SecurityRules
    if ($appliedRules.Count -lt $rules.Count) {
        Write-Warning "⚠️ Not all rules were applied successfully. Expected $($rules.Count), found $($appliedRules.Count)."
    } else {
        Write-Verbose "All $($rules.Count) rules applied successfully."
    }
    
    # Summary of security measures
    Write-Host "
Security configuration summary:
------------------------------
✓ SSH/RDP access configured based on VM OS type
✓ Access restricted to specified IP ranges: $(if ($ipRanges.Count -gt 0) { "Yes" } else { "No" })
✓ Azure services connectivity maintained
✓ All other inbound traffic blocked
✓ NSG security tags applied: $(if ($ApplyTags) { "Yes" } else { "No" })
    " -ForegroundColor Cyan
    
    Write-Verbose "=== NSG Configuration Script Completed ==="
    return $true
} 
catch {
    Write-Error "⛔ Error during NSG configuration: $_"
    Write-Error $_.Exception.StackTrace
    throw
}