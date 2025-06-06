<#
    File: scripts/assign-subscriptions.ps1
    Purpose: Assign existing subscriptions to existing management groups
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
        return
    }
    
    Write-Host "▸ Assigning subscription $subscriptionId to management group: $mgName" -ForegroundColor Cyan
    
    try {
        $result = az account management-group subscription add --name $mgName --subscription $subscriptionId
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully assigned subscription to management group '$mgName'." -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Command returned non-zero exit code when assigning to management group '$mgName'." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to assign subscription to management group '$mgName' - Error: $_" -ForegroundColor Red
        return $false
    }
}

# List available subscriptions to verify they're accessible
Write-Host "Verifying available subscriptions:" -ForegroundColor Cyan
az account list --output table

# Define subscription variables
$managementSubId = "c0b5b2a1-3e7b-46a4-9c0f-359b663ed31f"  # Management-Sub
$identitySubId = "2a931799-daea-4d93-94f8-0244704b5d06"     # Identity-Sub
$connectivitySubId = "cbd07569-930e-4b91-93b2-e6e87bdf02ed" # Connectivity-Sub
$landingZoneP1SubId = "0982688a-6198-414f-aecd-0a55776bbfd0" # LandingZone-P1-Sub
$landingZoneA2SubId = "00bf28e6-523a-432b-8840-3c572cf4e12e" # LandingZone-A2-Sub

# Verify management groups exist
Write-Host "Verifying management groups exist:" -ForegroundColor Cyan
az account management-group list --output table

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

Write-Host "Subscription IDs:" -ForegroundColor Cyan
Write-Host "Management-Sub: $managementSubId" -ForegroundColor Cyan
Write-Host "Identity-Sub: $identitySubId" -ForegroundColor Cyan
Write-Host "Connectivity-Sub: $connectivitySubId" -ForegroundColor Cyan
Write-Host "LandingZone-P1-Sub: $landingZoneP1SubId" -ForegroundColor Cyan
Write-Host "LandingZone-A2-Sub: $landingZoneA2SubId" -ForegroundColor Cyan
