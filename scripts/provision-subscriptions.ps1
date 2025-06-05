<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions and assign them into Management Groups

    IMPORTANT:
    • Make sure $billingAccountName and $billingProfileName match your own billing account/profile.
    • The SP that’s logging in needs Billing Reader on the billing account and
      “User Access Administrator” on the tenant root (/) so it can assign subscriptions into MGs.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match your environment
# ───────────────────────────────────────────────────────────────────────────────

# Your Billing Account ID (format: "<billingAccountGUID>:<billingProfileGUID>")
$billingAccountName = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

# Your Billing Profile Name (or ID); you can get it via `az billing billing-profile list` in your tenant
$billingProfileName = "6RX4-VIIG-BG7-PGB"

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

    # This command comes from the “account” extension (in preview)
    $jsonOutput = az billing subscription create `
        --billing-account-name $billingAccountName `
        --billing-profile-name $billingProfileName `
        --display-name $($s.Name) ` 
        --sku-id "0001" `
        --output json 

    $creationResult = $jsonOutput | ConvertFrom-Json

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
        continue
    }

    Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green

    # Give Azure a moment to finish provisioning
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan

    az account management-group subscription add `
        --name $($s.MG) `
        --subscription $creationResult.id

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done provisioning subscriptions and assigning them into MGs." -ForegroundColor Yellow
