<#
    File: scripts/assign-subscriptions-powershell.ps1
    Purpose: Assign existing subscriptions to existing management groups using PowerShell Az module
    Current Date: 2025-06-06
    User: GEP-V
#>

# Function to assign a subscription to a management group
function Assign-SubscriptionToManagementGroup {
    param (
        [string] $subscriptionId,
        [string] $mgName
    )
    
    if (-not $subscriptionId) {
        Write-Host "⚠️ No subscription ID provided for management group '$mgName'. Skipping." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "▸ Assigning subscription $subscriptionId to management group: $mgName" -ForegroundColor Cyan
    
    try {
        # Use PowerShell Az cmdlet to assign subscription
        New-AzManagementGroupSubscription -GroupId $mgName -SubscriptionId $subscriptionId
        Write-Host "✅ Successfully assigned subscription to management group '$mgName'." -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Host "❌ Failed to assign subscription to management group '$mgName' - Error: $_" -ForegroundColor Red
        return $false
    }
}

# Check if Az module is installed, if not, try to install it
if (!(Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Host "Az.Resources module not found. Attempting to install..." -ForegroundColor Yellow
    Install-Module -Name Az.Resources -Scope CurrentUser -Force
}

# Connect to Azure (will be skipped if already connected)
try {
    $context = Get-AzContext
    if (!$context) {
        Connect-AzAccount
    }
    else {
        Write-Host "Already connected to Azure as $($context.Account)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Please connect to Azure first using Connect-AzAccount" -ForegroundColor Red
    Connect-AzAccount
}

# Define subscription variables
$managementSubId = "c0b5b2a1-3e7b-46a4-9c0f-359b663ed31f"  # Management-Sub
$identitySubId = "2a931799-daea-4d93-94f8-0244704b5d06"     # Identity-Sub
$connectivitySubId = "cbd07569-930e-4b91-93b2-e6e87bdf02ed" # Connectivity-Sub
$landingZoneP1SubId = "0982688a-6198-414f-aecd-0a55776bbfd0" # LandingZone-P1-Sub
$landingZoneA2SubId = "00bf28e6-523a-432b-8840-3c572cf4e12e" # LandingZone-A2-Sub

# Create a tracking variable for successful assignments
$successCount = 0

# Assign subscriptions to management groups
if (Assign-SubscriptionToManagementGroup -subscriptionId $managementSubId -mgName "Management") {
    $successCount++
}

if (Assign-SubscriptionToManagementGroup -subscriptionId $identitySubId -mgName "Identity") {
    $successCount++
}

if (Assign-SubscriptionToManagementGroup -subscriptionId $connectivitySubId -mgName "Connectivity") {
    $successCount++
}

if (Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneP1SubId -mgName "Landing-Zones") {
    $successCount++
}

if (Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneA2SubId -mgName "Landing-Zones") {
    $successCount++
}

# Output summary
Write-Host "Assignment Summary:" -ForegroundColor Yellow
Write-Host "Successfully assigned $successCount out of 5 subscriptions" -ForegroundColor Yellow

if ($successCount -eq 5) {
    Write-Host "✅ All subscriptions successfully assigned to management groups!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some subscription assignments failed. Please review the logs above." -ForegroundColor Yellow
}
