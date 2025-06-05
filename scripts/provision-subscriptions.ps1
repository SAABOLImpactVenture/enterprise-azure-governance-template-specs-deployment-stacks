# Azure Subscription Provisioning Script for Microsoft Customer Agreement
# Last Updated: 2025-06-05 20:53:51 UTC
# Current User: GEP-V

# Configuration - Using the exact billing information provided
$invoiceSectionId = "A3HN-2BWX-PJA-PGB"
$billingProfileId = "6RX4-VYIG-BG7-PGB"
$billingAccountId = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

function Create-Subscription {
    param (
        [string]$subscriptionName
    )
    
    Write-Host "▸ Creating subscription: $subscriptionName"
    
    # Using the complete billing information with IDs rather than names
    $result = az account sub create --name "$subscriptionName" `
                                   --billing-account "$billingAccountId" `
                                   --billing-profile "$billingProfileId" `
                                   --invoice-section "$invoiceSectionId" `
                                   --output json
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "X Failed to create subscription '$subscriptionName' – no ID returned."
        return $null
    }
    
    $subscriptionObject = $result | ConvertFrom-Json
    Write-Host "✅ Successfully created subscription: $subscriptionName with ID: $($subscriptionObject.subscriptionId)"
    return $subscriptionObject.subscriptionId
}

function Assign-SubscriptionToManagementGroup {
    param (
        [string]$subscriptionId,
        [string]$managementGroupId
    )
    
    if (-not $subscriptionId) {
        Write-Warning "Cannot assign null subscription ID to management group $managementGroupId"
        return
    }
    
    Write-Host "▸ Assigning subscription $subscriptionId to management group: $managementGroupId"
    $result = az account management-group subscription add --name $managementGroupId --subscription $subscriptionId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "X Failed to assign subscription $subscriptionId to management group $managementGroupId"
    } else {
        Write-Host "✅ Successfully assigned subscription to management group: $managementGroupId"
    }
}

# Create subscriptions
$managementSubId = Create-Subscription -subscriptionName "Management-Sub"
$identitySubId = Create-Subscription -subscriptionName "Identity-Sub"
$connectivitySubId = Create-Subscription -subscriptionName "Connectivity-Sub"
$landingZoneP1SubId = Create-Subscription -subscriptionName "LandingZone-P1-Sub"
$landingZoneA2SubId = Create-Subscription -subscriptionName "LandingZone-A2-Sub"
$sandboxSubId = Create-Subscription -subscriptionName "Sandbox-Sub"

# Wait a moment for subscriptions to be fully provisioned before assigning to management groups
Write-Host "Waiting 30 seconds for subscriptions to be fully provisioned..."
Start-Sleep -Seconds 30

# Assign to management groups (assuming these exist)
if ($managementSubId) { Assign-SubscriptionToManagementGroup -subscriptionId $managementSubId -managementGroupId "Management" }
if ($identitySubId) { Assign-SubscriptionToManagementGroup -subscriptionId $identitySubId -managementGroupId "Identity" }
if ($connectivitySubId) { Assign-SubscriptionToManagementGroup -subscriptionId $connectivitySubId -managementGroupId "Connectivity" }
if ($landingZoneP1SubId) { Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneP1SubId -managementGroupId "LandingZones" }
if ($landingZoneA2SubId) { Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneA2SubId -managementGroupId "LandingZones" }
if ($sandboxSubId) { Assign-SubscriptionToManagementGroup -subscriptionId $sandboxSubId -managementGroupId "Sandbox" }

# Check if any subscriptions were created successfully
$createdSubs = @($managementSubId, $identitySubId, $connectivitySubId, $landingZoneP1SubId, $landingZoneA2SubId, $sandboxSubId) | Where-Object { $_ }
if ($createdSubs.Count -gt 0) {
    Write-Host "✅ Successfully created $($createdSubs.Count) subscriptions."
    Write-Host "✅ All done! Subscriptions created & assigned into Management Groups."
} else {
    Write-Error "❌ Failed to create any subscriptions."
}