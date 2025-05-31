# Variables – replace with your actual values
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "<your-resource-group>"
$vmName = "<your-vm-name>"
$workspaceResourceId = "/subscriptions/<your-subscription-id>/resourceGroups/<your-log-analytics-rg>/providers/Microsoft.OperationalInsights/workspaces/<your-workspace-name>"

# Login and set subscription context
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Retrieve the VM resource ID
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$vmResourceId = $vm.Id

# Define diagnostic setting name
$diagSettingName = "VM-Diagnostics"

# Create the diagnostic settings
Set-AzDiagnosticSetting `
  -Name $diagSettingName `
  -ResourceId $vmResourceId `
  -WorkspaceId $workspaceResourceId `
  -Enabled $true `
  -Category "AllMetrics","PerformanceCounters","EventLogs","Administrative","Security" `
  -RetentionEnabled $false
