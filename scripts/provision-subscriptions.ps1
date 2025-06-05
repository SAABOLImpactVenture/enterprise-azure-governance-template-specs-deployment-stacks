# Azure Subscription Provisioning Script for Microsoft Customer Agreement
# Last Updated: 2025-06-05 21:26:33 UTC
# Current User: GEP-V

# Configuration - Using the billing information provided
$invoiceSectionId = "A3HN-2BWX-PJA-PGB"
$billingProfileId = "6RX4-VYIG-BG7-PGB"
$billingAccountId = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

# Check if subscriptions already exist to prevent duplicate creation
function Get-ExistingSubscription {
    param (
        [string]$subscriptionName
    )
    
    Write-Host "▸ Checking if subscription '$subscriptionName' already exists..."
    $existingSub = az account list --query "[?name=='$subscriptionName'].id" -o tsv 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $existingSub) {
        Write-Host "✅ Found existing subscription '$subscriptionName' with ID: $existingSub"
        return $existingSub
    }
    
    return $null
}

function Create-SubscriptionAlias {
    param (
        [string]$subscriptionName,
        [int]$retryCount = 120,  # Doubled to 10 minutes
        [int]$sleepSeconds = 5,
        [int]$initialBackoffSeconds = 60  # Initial backoff for rate limiting
    )
    
    # First check if subscription already exists
    $existingSubId = Get-ExistingSubscription -subscriptionName $subscriptionName
    if ($existingSubId) {
        return $existingSubId
    }
    
    Write-Host "▸ Creating subscription alias for: $subscriptionName"
    
    # Generate a unique alias ID (required for alias creation)
    $aliasId = "$($subscriptionName.ToLower().Replace(" ", "-"))-$((New-Guid).ToString().Substring(0,8))".ToLower()
    
    # Create the subscription alias with retries for rate limiting
    $backoffSeconds = $initialBackoffSeconds
    $maxBackoffSeconds = 900  # 15 minutes max backoff
    $success = $false
    $attempt = 1
    
    while (-not $success -and $attempt -le 5) { # Max 5 attempts with exponential backoff
        Write-Host "  Creation attempt $attempt with $backoffSeconds seconds backoff if rate limited..."
        
        $result = az account alias create `
                  --name "$aliasId" `
                  --billing-scope "/providers/Microsoft.Billing/billingAccounts/$billingAccountId/billingProfiles/$billingProfileId/invoiceSections/$invoiceSectionId" `
                  --display-name "$subscriptionName" `
                  --workload "Production" `
                  --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $success = $true
            Write-Host "  Subscription alias created successfully."
        }
        else {
            if ($result -match "TooManyRequests") {
                # Extract wait time if specified
                if ($result -match "Retry in (\d+):(\d+):(\d+)") {
                    $hours = [int]$Matches[1]
                    $minutes = [int]$Matches[2]
                    $seconds = [int]$Matches[3]
                    $waitSeconds = ($hours * 3600) + ($minutes * 60) + $seconds
                    
                    # Use the suggested wait time or our backoff, whichever is greater
                    $backoffSeconds = [Math]::Max($waitSeconds, $backoffSeconds)
                }
                
                Write-Host "  Rate limit hit. Backing off for $backoffSeconds seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $backoffSeconds
                
                # Exponential backoff with 20% jitter
                $jitter = Get-Random -Minimum 0.8 -Maximum 1.2
                $backoffSeconds = [Math]::Min([int]($backoffSeconds * 2 * $jitter), $maxBackoffSeconds)
                $attempt++
            }
            else {
                # Non-rate limit error, fail immediately
                Write-Error "X Failed to create subscription alias '$aliasId' - Error: $result"
                return $null
            }
        }
    }
    
    if (-not $success) {
        Write-Error "X Failed to create subscription alias after 5 attempts with backoff."
        return $null
    }
    
    Write-Host "  Subscription alias created, waiting for provisioning to complete..."
    
    # Wait for the subscription to be provisioned
    $attempts = 0
    $subscriptionId = $null
    $jsonResult = $null
    
    while ($attempts -lt $retryCount) {
        $attempts++
        
        $status = az account alias show --name "$aliasId" --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  Could not retrieve alias status (attempt $attempts of $retryCount): $status"
        }
        else {
            try {
                $statusObj = $status | ConvertFrom-Json
                
                if ($statusObj.properties.provisioningState -eq "Succeeded") {
                    $subscriptionId = $statusObj.properties.subscriptionId
                    Write-Host "✅ Subscription successfully provisioned after $attempts attempts."
                    Write-Host "✅ New subscription name: $subscriptionName, ID: $subscriptionId"
                    $jsonResult = $statusObj
                    break
                }
                elseif ($statusObj.properties.provisioningState -eq "Failed") {
                    Write-Error "X Subscription provisioning failed: $($statusObj.properties.error.message)"
                    return $null
                }
                else {
                    Write-Host "  Provisioning state: $($statusObj.properties.provisioningState) (attempt $attempts of $retryCount)"
                }
            }
            catch {
                Write-Warning "  Error parsing status JSON: $_"
                Write-Host "  Raw status: $status"
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
    
    # Wait additional time after successful creation to avoid rate limits
    Write-Host "  Waiting 90 seconds before next subscription creation to avoid rate limits..." -ForegroundColor Cyan
    Start-Sleep -Seconds 90
    
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

# Create subscriptions with proper spacing and backoff
Write-Host "Starting subscription provisioning process..." -ForegroundColor Cyan

# Create management subscription
$managementSubId = Create-SubscriptionAlias -subscriptionName "Management-Sub"

# Create identity subscription
$identitySubId = Create-SubscriptionAlias -subscriptionName "Identity-Sub"

# Create connectivity subscription
$connectivitySubId = Create-SubscriptionAlias -subscriptionName "Connectivity-Sub"

# Create landing zone subscriptions
$landingZoneP1SubId = Create-SubscriptionAlias -subscriptionName "LandingZone-P1-Sub"
$landingZoneA2SubId = Create-SubscriptionAlias -subscriptionName "LandingZone-A2-Sub"

# Create sandbox subscription
$sandboxSubId = Create-SubscriptionAlias -subscriptionName "Sandbox-Sub"

# Wait for subscriptions to be fully registered in the system
Write-Host "Waiting 60 seconds for subscriptions to be fully registered in the system..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

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
    Write-Host "✅ Successfully created/verified $($createdSubs.Count) subscriptions." -ForegroundColor Green
    Write-Host "✅ All done! Subscriptions created & assigned into Management Groups." -ForegroundColor Green
} else {
    Write-Error "❌ Failed to create any subscriptions."
}