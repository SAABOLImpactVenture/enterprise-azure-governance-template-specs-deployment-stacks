# Azure Subscription Provisioning Script for Microsoft Customer Agreement
# Last Updated: 2025-06-05 21:02:22 UTC
# Current User: GEP-V

# Configuration - Using the billing information provided
$invoiceSectionId = "A3HN-2BWX-PJA-PGB"
$billingProfileId = "6RX4-VYIG-BG7-PGB"
$billingAccountId = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

function Create-SubscriptionAlias {
    param (
        [string]$subscriptionName,
        [int]$retryCount = 60,
        [int]$sleepSeconds = 5
    )
    
    Write-Host "▸ Creating subscription alias for: $subscriptionName"
    
    # Generate a unique alias ID (required for alias creation)
    $aliasId = "$($subscriptionName)-$((New-Guid).ToString().Substring(0,8))".ToLower()
    
    # Create the subscription alias
    $result = az account alias create `
              --name "$aliasId" `
              --billing-scope "/providers/Microsoft.Billing/billingAccounts/$billingAccountId/billingProfiles/$billingProfileId/invoiceSections/$invoiceSectionId" `
              --display-name "$subscriptionName" `
              --workload "Production" `
              --output json 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "X Failed to create subscription alias '$aliasId' - Error: $result"
        return $null
    }
    
    Write-Host "  Subscription alias created, waiting for provisioning to complete..."
    
    # Wait for the subscription to be provisioned
    $attempts = 0
    $subscriptionId = $null
    
    while ($attempts -lt $retryCount) {
        $attempts++
        
        $status = az account alias show --name "$aliasId" --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  Could not retrieve alias status (attempt $attempts of $retryCount): $status"
        }
        else {
            $statusObj = $status | ConvertFrom-Json
            
            if ($statusObj.provisioningState -eq "Succeeded") {
                $subscriptionId = $statusObj.properties.subscriptionId
                Write-Host "✅ Subscription successfully provisioned after $attempts attempts."
                Write-Host "✅ New subscription name: $subscriptionName, ID: $subscriptionId"
                break
            }
            elseif ($statusObj.provisioningState -eq "Failed") {
                Write-Error "X Subscription provisioning failed: $($statusObj.error.message)"
                return $null
            }
            else {
                Write-Host "  Provisioning state: $($statusObj.provisioningState) (attempt $attempts of $retryCount)"
            }
        }
        
        if ($attempts -lt $retryCount) {
            Start-Sleep -Seconds $sleepSeconds
        }
    }
    
    if ($null -eq $subscriptionId) {
        Write-Error "X Subscription was not provisioned within the expected time ($($retryCount * $sleepSeconds) seconds)"
        return $null
    }
    
    return $subscriptionId
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
    $result = az account management-group subscription add --name $managementGroupId --subscription $subscriptionId 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "X Failed to assign subscription $subscriptionId to management group $managementGroupId - Error: $result"
    } else {
        Write-Host "✅ Successfully assigned subscription to management group: $managementGroupId"
    }
}

# Create subscriptions
Write-Host "Starting subscription provisioning process..." -ForegroundColor Cyan
$managementSubId = Create-SubscriptionAlias -subscriptionName "Management-Sub"
$identitySubId = Create-SubscriptionAlias -subscriptionName "Identity-Sub"
$connectivitySubId = Create-SubscriptionAlias -subscriptionName "Connectivity-Sub"
$landingZoneP1SubId = Create-SubscriptionAlias -subscriptionName "LandingZone-P1-Sub"
$landingZoneA2SubId = Create-SubscriptionAlias -subscriptionName "LandingZone-A2-Sub"
$sandboxSubId = Create-SubscriptionAlias -subscriptionName "Sandbox-Sub"

# Wait a moment for subscriptions to be fully registered in the system
Write-Host "Waiting 30 seconds for subscriptions to be fully registered in the system..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Assign to management groups
Write-Host "Starting management group assignment process..." -ForegroundColor Cyan
if ($managementSubId) { Assign-SubscriptionToManagementGroup -subscriptionId $managementSubId -managementGroupId "Management" }
if ($identitySubId) { Assign-SubscriptionToManagementGroup -subscriptionId $identitySubId -managementGroupId "Identity" }
if ($connectivitySubId) { Assign-SubscriptionToManagementGroup -subscriptionId $connectivitySubId -managementGroupId "Connectivity" }
if ($landingZoneP1SubId) { Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneP1SubId -managementGroupId "LandingZones" }
if ($landingZoneA2SubId) { Assign-SubscriptionToManagementGroup -subscriptionId $landingZoneA2SubId -managementGroupId "LandingZones" }
if ($sandboxSubId) { Assign-SubscriptionToManagementGroup -subscriptionId $sandboxSubId -managementGroupId "Sandbox" }

# Summarize results
$createdSubs = @($managementSubId, $identitySubId, $connectivitySubId, $landingZoneP1SubId, $landingZoneA2SubId, $sandboxSubId) | Where-Object { $_ }
if ($createdSubs.Count -gt 0) {
    Write-Host "✅ Successfully created $($createdSubs.Count) subscriptions." -ForegroundColor Green
    Write-Host "✅ All done! Subscriptions created & assigned into Management Groups." -ForegroundColor Green
} else {
    Write-Error "❌ Failed to create any subscriptions."
}