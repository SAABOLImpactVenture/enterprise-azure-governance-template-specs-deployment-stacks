<#
.SYNOPSIS
    Enables Azure Diagnostics and Monitoring for virtual machines.
    
.DESCRIPTION
    This script configures Azure Diagnostics extension for both Windows and Linux VMs,
    enabling performance counters, logs collection, and optionally connects to 
    Log Analytics workspace for enhanced monitoring and alerting.
    
.PARAMETER VMName
    The name of the virtual machine to configure diagnostics for.
    
.PARAMETER ResourceGroup
    The resource group containing the VM.
    
.PARAMETER SubscriptionId
    Optional. The Azure subscription ID. If not provided, uses the current context.
    
.PARAMETER StorageAccountName
    Optional. Storage account for diagnostics data. If not provided, attempts to
    use an existing diagnostic storage account in the same resource group or creates one.
    
.PARAMETER LogAnalyticsWorkspaceId
    Optional. Resource ID of Log Analytics workspace to connect the VM to.
    
.PARAMETER EnableMetrics
    Optional. Enable collection of performance metrics. Default is true.
    
.PARAMETER EnableLogs
    Optional. Enable collection of system logs. Default is true.
    
.EXAMPLE
    ./enable-diagnostics.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab"
    
.EXAMPLE
    ./enable-diagnostics.ps1 -VMName "devtestvm01" -ResourceGroup "rg-devtest-lab" -LogAnalyticsWorkspaceId "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-monitoring/providers/microsoft.operationalinsights/workspaces/law-central"
    
.NOTES
    Last Updated: 2025-06-06 23:18:25
    Current User's Login: GEP-V
    
    This script enables:
    - Performance metrics collection (CPU, memory, disk, network)
    - System logs collection
    - Boot diagnostics
    - Optional Log Analytics integration
    
    Best Practices:
    - Use a dedicated storage account for diagnostics
    - Connect VMs to Log Analytics for centralized monitoring
    - Enable both metrics and logs for comprehensive monitoring
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "",
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$LogAnalyticsWorkspaceId = "",
    
    [Parameter(Mandatory = $false)]
    [bool]$EnableMetrics = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$EnableLogs = $true
)

# Script constants
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$diagnosticsStorageAccountType = "Standard_LRS"

Write-Verbose "=== VM Diagnostics Configuration Started ==="
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
    
    # Get the VM
    Write-Verbose "Getting VM details..."
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction Stop
    
    if (-not $vm) {
        throw "VM '$VMName' not found in resource group '$ResourceGroup'."
    }
    
    # Determine VM OS type
    Write-Verbose "Determining VM OS type..."
    $osType = $vm.StorageProfile.OsDisk.OsType
    Write-Verbose "OS Type: $osType"
    
    # Handle storage account for diagnostics
    if ([string]::IsNullOrEmpty($StorageAccountName)) {
        Write-Verbose "Storage account name not provided. Finding or creating diagnostic storage account..."
        
        # Try to find an existing diagnostics storage account
        $saPrefix = "diag"
        $saList = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        $diagSA = $saList | Where-Object { $_.StorageAccountName -like "$saPrefix*" } | Select-Object -First 1
        
        if ($diagSA) {
            $StorageAccountName = $diagSA.StorageAccountName
            Write-Verbose "Using existing diagnostic storage account: $StorageAccountName"
        } else {
            # Create a new diagnostics storage account with unique name
            $uniqueId = -join ((48..57) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
            $StorageAccountName = "$saPrefix$uniqueId"
            Write-Verbose "Creating new diagnostic storage account: $StorageAccountName"
            
            New-AzStorageAccount -ResourceGroupName $ResourceGroup `
                -Name $StorageAccountName `
                -Location $vm.Location `
                -SkuName $diagnosticsStorageAccountType `
                -Kind StorageV2 `
                -ErrorAction Stop | Out-Null
                
            Write-Verbose "Storage account created: $StorageAccountName"
        }
    } else {
        # Verify the provided storage account exists
        Write-Verbose "Verifying specified storage account: $StorageAccountName"
        $sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName -ErrorAction SilentlyContinue
        
        if (-not $sa) {
            throw "Storage account '$StorageAccountName' not found in resource group '$ResourceGroup'."
        }
    }
    
    # Enable Boot Diagnostics
    Write-Verbose "Enabling boot diagnostics..."
    $bootDiagStorageUri = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName).PrimaryEndpoints.Blob
    
    Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccountName -ErrorAction Stop
    Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm -ErrorAction Stop | Out-Null
    Write-Verbose "Boot diagnostics enabled"
    
    # Configure and enable diagnostics extension based on OS type
    if ($osType -eq "Windows") {
        Write-Verbose "Configuring Windows diagnostics extension..."
        
        # Prepare Windows diagnostics configuration
        $publicSettings = @{
            storageAccountName = $StorageAccountName
            WadCfg = @{
                DiagnosticMonitorConfiguration = @{
                    overallQuotaInMB = 5120
                    DiagnosticInfrastructureLogs = @{
                        scheduledTransferLogLevelFilter = "Verbose"
                    }
                }
            }
        }
        
        # Add performance counters if enabled
        if ($EnableMetrics) {
            Write-Verbose "Adding Windows performance counters..."
            $publicSettings.WadCfg.DiagnosticMonitorConfiguration.PerformanceCounters = @{
                scheduledTransferPeriod = "PT1M"
                PerformanceCounterConfiguration = @(
                    @{
                        counterSpecifier = "\Processor(_Total)\% Processor Time"
                        sampleRate = "PT60S"
                    },
                    @{
                        counterSpecifier = "\Memory\Available MBytes"
                        sampleRate = "PT60S"
                    },
                    @{
                        counterSpecifier = "\Network Interface(*)\Bytes Total/sec"
                        sampleRate = "PT60S"
                    },
                    @{
                        counterSpecifier = "\LogicalDisk(_Total)\Disk Read Bytes/sec"
                        sampleRate = "PT60S"
                    },
                    @{
                        counterSpecifier = "\LogicalDisk(_Total)\Disk Write Bytes/sec"
                        sampleRate = "PT60S"
                    }
                )
            }
        }
        
        # Add Windows event logs if enabled
        if ($EnableLogs) {
            Write-Verbose "Adding Windows event logs collection..."
            $publicSettings.WadCfg.DiagnosticMonitorConfiguration.WindowsEventLog = @{
                scheduledTransferPeriod = "PT1M"
                DataSource = @(
                    @{
                        name = "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
                    },
                    @{
                        name = "System!*[System[(Level=1 or Level=2 or Level=3)]]"
                    },
                    @{
                        name = "Security!*[System[(Level=1)]]"
                    }
                )
            }
        }
        
        $privateSettings = @{
            storageAccountName = $StorageAccountName
            storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccountName)[0].Value
        }
        
        # Set Windows diagnostics extension
        $winDiagExtension = Set-AzVMDiagnosticsExtension `
            -ResourceGroupName $ResourceGroup `
            -VMName $VMName `
            -Publisher "Microsoft.Azure.Diagnostics" `
            -ExtensionType "IaaSDiagnostics" `
            -Name "WindowsDiagnostics" `
            -SettingString (ConvertTo-Json -Depth 10 -Compress $publicSettings) `
            -ProtectedSettingString (ConvertTo-Json -Compress $privateSettings) `
            -TypeHandlerVersion "1.5"
            
    } else {
        # Linux VM diagnostics configuration
        Write-Verbose "Configuring Linux diagnostics extension..."
        
        # Prepare Linux diagnostics configuration
        $publicSettings = @{
            StorageAccount = $StorageAccountName
            ladCfg = @{
                diagnosticMonitorConfiguration = @{
                    eventVolume = "Medium"
                    metrics = @{
                        metricAggregation = @(
                            @{
                                scheduledTransferPeriod = "PT1H"
                            },
                            @{
                                scheduledTransferPeriod = "PT1M"
                            }
                        )
                    }
                    syslogEvents = @{}
                }
            }
        }
        
        # Add Linux performance metrics if enabled
        if ($EnableMetrics) {
            Write-Verbose "Adding Linux performance counters..."
            $publicSettings.ladCfg.diagnosticMonitorConfiguration.performanceCounters = @{
                sinks = "MyMetricsSink"
                performanceCounterConfiguration = @(
                    @{
                        unit = "Percent"
                        type = "builtin" 
                        counter = "PercentProcessorTime"
                        counterSpecifier = "/builtin/Processor/PercentProcessorTime"
                        annotation = @( 
                            @{
                                displayName = "CPU utilization" 
                                locale = "en-us"
                            }
                        )
                    },
                    @{
                        unit = "Bytes"
                        type = "builtin" 
                        counter = "UsedMemory"
                        counterSpecifier = "/builtin/Memory/UsedMemory"
                        annotation = @(
                            @{
                                displayName = "Memory used" 
                                locale = "en-us"
                            }
                        )
                    },
                    @{
                        unit = "Bytes"
                        type = "builtin" 
                        counter = "PercentUsedSpace"
                        counterSpecifier = "/builtin/FileSystem/PercentUsedSpace"
                        annotation = @(
                            @{
                                displayName = "Disk space used (%)" 
                                locale = "en-us"
                            }
                        )
                    }
                )
            }
        }
        
        # Add Linux syslog collection if enabled
        if ($EnableLogs) {
            Write-Verbose "Adding Linux syslog collection..."
            $publicSettings.ladCfg.diagnosticMonitorConfiguration.syslogEvents = @{
                sinks = "MySyslogSink"
                syslogEventConfiguration = @{
                    "LOG_AUTH" = "LOG_INFO"
                    "LOG_AUTHPRIV" = "LOG_INFO"
                    "LOG_CRON" = "LOG_INFO"
                    "LOG_DAEMON" = "LOG_INFO"
                    "LOG_KERN" = "LOG_INFO"
                    "LOG_LOCAL0" = "LOG_INFO"
                    "LOG_LOCAL1" = "LOG_INFO"
                    "LOG_LOCAL2" = "LOG_INFO"
                    "LOG_LOCAL3" = "LOG_INFO"
                    "LOG_LOCAL4" = "LOG_INFO"
                    "LOG_LOCAL5" = "LOG_INFO"
                    "LOG_LOCAL6" = "LOG_INFO"
                    "LOG_LOCAL7" = "LOG_INFO"
                    "LOG_USER" = "LOG_INFO"
                }
            }
        }
        
        $privateSettings = @{
            storageAccountName = $StorageAccountName
            storageAccountSasToken = (New-AzStorageAccountSASToken -Service Blob,Table -ResourceType Service,Container,Object -Permission "racwdlup" -Context (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName).Context -ExpiryTime (Get-Date).AddYears(10))
        }
        
        # Set Linux diagnostics extension
        $linuxDiagExtension = Set-AzVMExtension `
            -ResourceGroupName $ResourceGroup `
            -VMName $VMName `
            -Publisher "Microsoft.Azure.Diagnostics" `
            -ExtensionType "LinuxDiagnostic" `
            -Name "LinuxDiagnostics" `
            -Settings $publicSettings `
            -ProtectedSettings $privateSettings `
            -TypeHandlerVersion "4.0"
    }
    
    # Enable Log Analytics integration if workspace ID is provided
    if (-not [string]::IsNullOrEmpty($LogAnalyticsWorkspaceId)) {
        Write-Verbose "Configuring Log Analytics integration with workspace: $LogAnalyticsWorkspaceId"
        
        $OMSPublicSettings = @{
            workspaceId = (Get-AzOperationalInsightsWorkspace -ResourceId $LogAnalyticsWorkspaceId).CustomerId
        }
        
        $OMSProtectedSettings = @{
            workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceId $LogAnalyticsWorkspaceId).PrimarySharedKey
        }
        
        # Set Log Analytics extension based on OS
        if ($osType -eq "Windows") {
            Write-Verbose "Adding Windows Log Analytics agent..."
            Set-AzVMExtension `
                -ResourceGroupName $ResourceGroup `
                -VMName $VMName `
                -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                -ExtensionType "MicrosoftMonitoringAgent" `
                -Name "MicrosoftMonitoringAgent" `
                -Settings $OMSPublicSettings `
                -ProtectedSettings $OMSProtectedSettings `
                -TypeHandlerVersion "1.0" | Out-Null
        } else {
            Write-Verbose "Adding Linux Log Analytics agent..."
            Set-AzVMExtension `
                -ResourceGroupName $ResourceGroup `
                -VMName $VMName `
                -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                -ExtensionType "OmsAgentForLinux" `
                -Name "OmsAgentForLinux" `
                -Settings $OMSPublicSettings `
                -ProtectedSettings $OMSProtectedSettings `
                -TypeHandlerVersion "1.13" | Out-Null
        }
        
        Write-Verbose "Log Analytics integration complete"
    }
    
    Write-Host "✅ Diagnostics successfully configured for VM: $VMName" -ForegroundColor Green
    Write-Verbose "=== VM Diagnostics Configuration Completed ==="
    return $true
} 
catch {
    Write-Error "⛔ Error enabling diagnostics: $_"
    Write-Error $_.Exception.StackTrace
    throw
}