<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions and assign them into Management Groups

    IMPORTANT:
    • Make sure $billingAccountName and $billingProfileName match your own billing account/profile.
    • The SP that's logging in needs Billing Reader on the billing account and
      "User Access Administrator" on the tenant root (/) so it can assign subscriptions into MGs.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match your environment
# ───────────────────────────────────────────────────────────────────────────────

# Your Billing Account ID (format: "<billingAccountGUID>:<billingProfileGUID>")
$billingAccountName = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

# Your Billing Profile Name (or ID); you can get it via `az billing billing-profile list` in your tenant
$billingProfileName = "6RX4-VIIG-BG7-PGB"

# Your Invoice Section (you may need to obtain this from the Azure portal or CLI)
$invoiceSection = "6RX4-VIIG-BG7-PGB" # Often the same as billing profile for simple accounts

# ───────────────────────────────────────────────────────────────────────────────
# 2. Define which subscriptions to create & which Management Group to place them under
# ───────────────────────────────────────────────────────────────────────────────

# Each object must have a Name (friendly subscription name) and MG (existing MG name).
# You must have already created these management groups in Azure.
$subsToCreate = @(
    @{ Name = "Management-Sub";     MG = "Management-MG" },
    @{ Name = "Identity-Sub";       MG = "Identity-MG" },
    @{ Name = "Connectivity-Sub";   MG = "Connectivity-MG" },
    @{ Name = "LandingZone-P1-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "LandingZone-A2-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "Sandbox-Sub";        MG = "Sandbox-MG" }
)

# ───────────────────────────────────────────────────────────────────────────────
# 3. Loop through each subscription declaration, create it, then assign to MG
# ───────────────────────────────────────────────────────────────────────────────

foreach ($s in $subsToCreate) {

    Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan
    
    # Construct the complete billing scope as a literal string (not variable interpolation)
    $billingScope = "/providers/Microsoft.Billing/billingAccounts/$billingAccountName/billingProfiles/$billingProfileName/invoiceSections/$invoiceSection"
    
    Write-Host "Using billing scope: $billingScope" -ForegroundColor Gray
    
    # Use single quotes around the billing scope to prevent any PowerShell variable expansion issues
    $cliCommand = "az account alias create --name '$($s.Name)' --billing-scope '$billingScope' --display-name '$($s.Name)' --workload 'Production' --output json"
    
    Write-Host "Executing: $cliCommand" -ForegroundColor Gray
    
    try {
        $jsonOutput = Invoke-Expression $cliCommand
        $creationResult = $jsonOutput | ConvertFrom-Json
    }
    catch {
        Write-Error "Error executing command: $_"
        continue
    }

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
        continue
    }

    Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green

    # Give Azure a moment to finish provisioning
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan

    $mgCommand = "az account management-group subscription add --name '$($s.MG)' --subscription '$($creationResult.id)'"
    Invoke-Expression $mgCommand

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done provisioning subscriptions and assigning them into MGs." -ForegroundColor Yellow
