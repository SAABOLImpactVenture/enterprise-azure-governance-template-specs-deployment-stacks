<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions via `az billing subscription create` and assign them into Management Groups.

    IMPORTANT NOTES:
    • This script assumes that the SP (service principal) you are logging in with has:
        – “Billing Reader” rights on your Billing Account (so it can create new Pay-As-You-Go subscriptions),
        – “Management Group Contributor” (or higher) on each of the Management Groups (so it can add a subscription into that MG),
        – “User Access Administrator” (or Owner) at the tenant root scope (“/”) so it can perform the role assignment necessary to place subscriptions into MGs.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match YOUR billing account & billing profile
# ───────────────────────────────────────────────────────────────────────────────

# Your Billing Account ID (format: "<billingAccountGUID>:<billingProfileGUID>")
$billingAccountName   = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

# Your Billing Profile Name (or ID); you can get this via:
#     az billing billing-profile list --billing-account-name <BillingAccountID>
$billingProfileName   = "6RX4-VIIG-BG7-PGB"

# ───────────────────────────────────────────────────────────────────────────────
# 2. Define which subscriptions to create & which Management Group to place them under
# ───────────────────────────────────────────────────────────────────────────────

# Each has a “Name” (the display name of the new subscription) and the target Management Group (“MG”).
# Make sure these MGs already exist in your tenant.
$subsToCreate = @(
    @{ Name = "Management-Sub";     MG = "Management-MG" },
    @{ Name = "Identity-Sub";       MG = "Identity-MG" },
    @{ Name = "Connectivity-Sub";   MG = "Connectivity-MG" },
    @{ Name = "LandingZone-P1-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "LandingZone-A2-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "Sandbox-Sub";        MG = "Sandbox-MG" }
)

# ───────────────────────────────────────────────────────────────────────────────
# 3. Loop through each subscription definition, create it, then assign into MG
# ───────────────────────────────────────────────────────────────────────────────

foreach ($s in $subsToCreate) {

    Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan

    # We use the “billing” command (which resides in the built-in “billing” CLI extension)
    # to spin up a brand-new Pay-As-You-Go subscription under our billing account & profile.
    $cliParams = @(
        "billing", "subscription", "create",
        "--billing-account-name",  $billingAccountName,
        "--billing-profile-name",  $billingProfileName,
        "--display-name",          $($s.Name),
        "--sku-id",                "0001",          # “0001” == Pay-As-You-Go
        "--output",                "json"
    )
    $jsonOutput      = az @cliParams
    $creationResult  = $jsonOutput | ConvertFrom-Json

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
        continue
    }

    Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green

    # Wait a few seconds for Azure to finish provisioning behind the scenes
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan

    az account management-group subscription add `
        --name         $($s.MG) `
        --subscription $creationResult.id

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done – subscriptions created and assigned into Management Groups." -ForegroundColor Yellow
