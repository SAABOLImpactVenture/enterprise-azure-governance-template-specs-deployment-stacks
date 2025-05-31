# Replace with actual values from parameters
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "Dev_Test_Lab-demosmartcontract-vm-017910"
$vmName = "demosmartcontract-vm"
$diagnosticStorageAccountName = "<your-storage-account-name>"

# Login and set context
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Enable diagnostics
Set-AzVMDiagnosticsExtension -ResourceGroupName $resourceGroupName `
  -VMName $vmName `
  -StorageAccountName $diagnosticStorageAccountName `
  -Name "LinuxDiagnostics" `
  -Publisher "Microsoft.Azure.Diagnostics" `
  -Type "LinuxDiagnostic" `
  -TypeHandlerVersion "4.0" `
  -ProtectedSettingString "{}" `
  -SettingString '{"ladCfg": {"diagnosticMonitorConfiguration": {"performanceCounters": {"performanceCounterConfiguration": []}}}}'

Write-Host "Diagnostics enabled for VM: $vmName"
