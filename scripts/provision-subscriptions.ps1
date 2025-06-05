<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions and assign them into Management Groups

    Make sure to update $billingAccountName and $billingProfileName to match your own
    EA/MCA billing account + profile.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match your environment
# ───────────────────────────────────────────────────────────────────────────────

# This is your Billing Account ID (format: "<billingAccountGUID>:<billingProfileGUID>").
# You can find it via `az billing account list` or in the portal under Billing > Billing accounts.
$billingAccountName = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"

# This is your Billing Profile Name (or ID). You can find it via `az billing billing-profile list` or in the portal.
$billingProfileName = "6RX4-VIIG-BG7-PGB"

# ───────────────────────────────────────────────────────────────────────────────
# 2. Define which subscriptions to create, plus which Management Group each should go under
# ───────────────────────────────────────────────────────────────────────────────

# Each object needs a Name (the subscription’s friendly name) and MG (the Management Group name).
# You must have already created these Management Groups in your tenant.
$subsToCreate = @(
    @{ Name = "Management-Sub";       MG = "Management-MG" },
    @{ Name = "Identity-Sub";         MG = "Identity-MG" },
    @{ Name = "Connectivity-Sub";     MG = "Connectivity-MG" },
    @{ Name = "LandingZone-P1-Sub";   MG = "Landing-Zones-MG" },
    @{ Name = "LandingZone-A2-Sub";   MG = "Landing-Zones-MG" },
    @{ Name = "Sandbox-Sub";          MG = "Sandbox-MG" }
)

# ───────────────────────────────────────────────────────────────────────────────
# 3. Loop through each subscription definition, create it, then assign to MG
# ───────────────────────────────────────────────────────────────────────────────

foreach ($s in $subsToCreate) {

    Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan

    # This is the preview command that comes from the “subscription” extension
    $creationResult = az account subscription create `
        --subscription-name $($s.Name) `
        --offer-type        "Pay-As-You-Go" `
        --billing-account   $billingAccountName `
        --billing-profile   $billingProfileName `
        --output            json | ConvertFrom-Json

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned from Azure."
        continue
    }

    Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green

    # Short delay so Azure has time to finish provisioning
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan

    az account management-group subscription add `
        --name $($s.MG) `
        --subscription $creationResult.id

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done provisioning subscriptions and assigning them into MGs." -ForegroundColor Yellow
