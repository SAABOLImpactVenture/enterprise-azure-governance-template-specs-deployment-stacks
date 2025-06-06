<#
.SYNOPSIS
    Azure Subscription Provisioning Script for Microsoft Customer Agreement (Creation Only)

.DESCRIPTION
    This PowerShell script automates the creation of Azure subscriptions under a Microsoft Customer Agreement.
    It includes robust error handling, rate limiting protection, and verification of existing subscriptions
    to prevent duplicates. Management group assignment has been moved to a separate script.

.NOTES
    File Name      : provision-subscriptions.ps1
    Author         : GEP-V
    Last Updated   : 2025-06-06 16:45:28 UTC
    Environment    : GitHub Codespace
    
    GITHUB CODESPACE USAGE INSTRUCTIONS:
    1. Create this file in your GitHub Codespace
    2. Set up GitHub Secrets for billing information:
       - AZURE_INVOICE_SECTION_ID
       - AZURE_BILLING_PROFILE_ID
       - AZURE_BILLING_ACCOUNT_ID
    3. Open a PowerShell terminal: pwsh
    4. Run the script: ./provision-subscriptions.ps1
    5. If az CLI isn't installed, install it first:
       curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    6. Authenticate with: az login --use-device-code
    
    REQUIRED ENVIRONMENT VARIABLES:
    - AZURE_INVOICE_SECTION_ID: Invoice section ID from Microsoft Customer Agreement
    - AZURE_BILLING_PROFILE_ID: Billing profile ID from Microsoft Customer Agreement
    - AZURE_BILLING_ACCOUNT_ID: Billing account ID from Microsoft Customer Agreement
#>

# ===============================================================================
# SECTION 1: CONFIGURATION PARAMETERS
# ===============================================================================
# Get billing information from environment variables (set from GitHub Secrets)
# This approach keeps sensitive information out of your code repository
# ===============================================================================

# Get billing information from environment variables
$invoiceSectionId = $env:AZURE_INVOICE_SECTION_ID
$billingProfileId = $env:AZURE_BILLING_PROFILE_ID
$billingAccountId = $env:AZURE_BILLING_ACCOUNT_ID

# Validate required environment variables are set
if (-not $invoiceSectionId -or -not $billingProfileId -or -not $billingAccountId) {
    Write-Error "Missing required environment variables. Please ensure AZURE_INVOICE_SECTION_ID, AZURE_BILLING_PROFILE_ID, and AZURE_BILLING_ACCOUNT_ID are set."
    exit 1
}

Write-Host "Current Date and Time (UTC): 2025-06-06 16:45:28" -ForegroundColor Cyan
Write-Host "Current User's Login: GEP-V" -ForegroundColor Cyan
Write-Host "Environment: GitHub Codespace" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# SECTION 2: HELPER FUNCTIONS
# ===============================================================================

<#
.SYNOPSIS
    Checks if a subscription with the given name already exists.

.DESCRIPTION
    Queries Azure for existing subscriptions and returns the ID if found.
    This prevents duplicate subscription creation and allows the script
    to be run multiple times safely (idempotent).

.PARAMETER subscriptionName
    The display name of the subscription to look for

.RETURNS
    Subscription ID if found, null otherwise
#>
function Get-ExistingSubscription {
    param (
        [string]$subscriptionName
    )
    
    Write-Host "▸ Checking if subscription '$subscriptionName' already exists..."
    
    # Use --all flag to show all subscriptions regardless of state
    # Redirect stderr to null to suppress warnings
    # Use --query to get just the ID without any other text
    # AI PROMPT TIP: Include detailed comments for complex commands to help AI understand the intent
    $existingSub = az account list --all --query "[?name=='$subscriptionName'].id" -o tsv 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $existingSub) {
        # Clean the output - ensure we only have the GUID
        $existingSub = $existingSub.Trim()
        
        # Validate that it looks like a GUID
        if ($existingSub -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
            Write-Host "✅ Found existing subscription '$subscriptionName' with ID: $existingSub"
            return $existingSub
        }
        else {
            Write-Host "⚠️ Found subscription '$subscriptionName' but ID format is invalid: $existingSub"
            return $null
        }
    }
    
    Write-Host "  Subscription '$subscriptionName' not found."
    return $null
}

<#
.SYNOPSIS
    Creates a new Azure subscription under Microsoft Customer Agreement.

.DESCRIPTION
    Creates a subscription alias and waits for it to be fully provisioned.
    Includes retry logic with exponential backoff for rate limiting.
    
.PARAMETER subscriptionName
    The display name for the new subscription
    
.PARAMETER retryCount
    Maximum number of status check retries
    
.PARAMETER sleepSeconds
    Seconds to wait between status checks
    
.PARAMETER initialBackoffSeconds
    Initial backoff time in seconds if rate limited
    
.RETURNS
    Subscription ID if successful, null otherwise
#>
function Create-SubscriptionAlias {
    param (
        [string]$subscriptionName,
        [int]$retryCount = 120,
        [int]$sleepSeconds = 5,
        [int]$initialBackoffSeconds = 60
    )
    
    # First check if subscription already exists
    # AI PROMPT TIP: Design scripts to be idempotent whenever possible
    $existingSubId = Get-ExistingSubscription -subscriptionName $subscriptionName
    if ($existingSubId) {
        return $existingSubId
    }
    
    Write-Host "▸ Creating subscription alias for: $subscriptionName"
    
    # Generate a unique alias ID (required for alias creation)
    # Using a combination of name and random GUID ensures uniqueness
    $aliasId = "$($subscriptionName.ToLower().Replace(" ", "-"))-$((New-Guid).ToString().Substring(0,8))".ToLower()
    
    # Create the subscription alias with retries for rate limiting
    # Rate limiting is common with subscription creation, so robust handling is essential
    $backoffSeconds = $initialBackoffSeconds
    $maxBackoffSeconds = 900  # 15 minutes max backoff
    $success = $false
    $attempt = 1
    
    while (-not $success -and $attempt -le 5) {
        Write-Host "  Creation attempt $attempt with $backoffSeconds seconds backoff if rate limited..."
        
        # Execute the Azure CLI command to create subscription alias
        # This uses the Microsoft Customer Agreement billing scope format
        # AI PROMPT TIP: The exact billing scope format was critical for success
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
            # Handle rate limiting with intelligent backoff
            # This pattern is essential for any API that might implement rate limiting
            if ($result -match "TooManyRequests") {
                # Extract wait time if specified in the response
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
                
                # Exponential backoff with 20% jitter to prevent thundering herd problem
                # AI PROMPT TIP: Including jitter in retry logic is a best practice
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
    
    # Wait for the subscription to be fully provisioned
    # This is critical as the subscription isn't immediately available after creation
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
    # This prevents cascading failures when creating multiple subscriptions
    Write-Host "  Waiting 90 seconds before next subscription creation to avoid rate limits..." -ForegroundColor Cyan
    Start-Sleep -Seconds 90
    
    return $subscriptionId
}

# ===============================================================================
# SECTION 3: MAIN EXECUTION FLOW
# ===============================================================================

# Create subscriptions with proper spacing and backoff
Write-Host "Starting subscription provisioning process..." -ForegroundColor Cyan

# Create each subscription
# The script processes one subscription at a time to avoid rate limiting issues
# AI PROMPT TIP: When automating cloud resource creation, sequential processing
# with appropriate delays is often more reliable than parallel processing

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

# ===============================================================================
# SECTION 4: RESULTS SUMMARY
# ===============================================================================

# Debug - Show all available subscriptions for verification
Write-Host "Available subscriptions:" -ForegroundColor Cyan
az account list --all --output table

# Summarize results
$createdSubs = @($managementSubId, $identitySubId, $connectivitySubId, $landingZoneP1SubId, $landingZoneA2SubId, $sandboxSubId) | Where-Object { $_ }
if ($createdSubs.Count -gt 0) {
    Write-Host "✅ Successfully created/verified $($createdSubs.Count) subscriptions." -ForegroundColor Green
    
    # List all subscription IDs for reference
    Write-Host "Subscription IDs:" -ForegroundColor Green
    Write-Host "Management-Sub: $managementSubId"
    Write-Host "Identity-Sub: $identitySubId"
    Write-Host "Connectivity-Sub: $connectivitySubId"
    Write-Host "LandingZone-P1-Sub: $landingZoneP1SubId"
    Write-Host "LandingZone-A2-Sub: $landingZoneA2SubId"
    Write-Host "Sandbox-Sub: $sandboxSubId"
    
    Write-Host "✅ All done! Subscriptions created and ready for management group assignment." -ForegroundColor Green
    Write-Host "Note: Use assign-subscriptions.sh or assign-subscriptions.ps1 to assign these subscriptions to management groups." -ForegroundColor Yellow
} else {
    Write-Error "❌ Failed to create any subscriptions."
}

# ===============================================================================
# ADDITIONAL NOTES
# ===============================================================================
# This script demonstrates several key patterns for Azure subscription creation:
# 1. Idempotent operations (checking for existing resources)
# 2. Rate limit handling with exponential backoff and jitter
# 3. Proper error handling and validation
# 4. Progress tracking and clear status reporting
# 5. Secure handling of sensitive billing information via environment variables
#
# AI PROMPT TIP: When working with cloud resources, always include resource 
# discovery and validation steps before making changes. This ensures your
# automation works correctly despite variations in naming conventions or
# resource organization.
#
# Management group assignment functionality has been moved to a separate script
# for better separation of concerns.
