<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions and assign them into Management Groups.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1) Update these variables to match YOUR billing account & invoice section
# ───────────────────────────────────────────────────────────────────────────────

$billingAccountName  = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30"
$billingProfileName  = "6RX4-VIIG-BG7-PGB"
$invoiceSectionName  = "A3HN-2BWX-PJA-PGB"

# ───────────────────────────────────────────────────────────────────────────────
# 2) Define which subscriptions to create & their target Management Group
# ───────────────────────────────────────────────────────────────────────────────

$subsToCreate = @(
    @{ Name = "Management-Sub";     MG = "Management-MG"    },
    @{ Name = "Identity-Sub";       MG = "Identity-MG"      },
    @{ Name = "Connectivity-Sub";   MG = "Connectivity-MG"  },
    @{ Name = "LandingZone-P1-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "LandingZone-A2-Sub"; MG = "Landing-Zones-MG" },
    @{ Name = "Sandbox-Sub";        MG = "Sandbox-MG"       }
)

# ───────────────────────────────────────────────────────────────────────────────
# 3) Loop through each subscription, create it, then assign into MG
# ───────────────────────────────────────────────────────────────────────────────
foreach ($s in $subsToCreate) {
    Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan

    # This call will automatically cause the CLI to pull down the billing extension
    $cliParams = @(
        "billing", "subscription", "create",
        "--billing-account-name",  $billingAccountName,
        "--billing-profile-name",  $billingProfileName,
        "--invoice-section-name",  $invoiceSectionName,
        "--display-name",          $($s.Name),
        "--sku-id",                "0001",       # 0001 = Pay-As-You-Go
        "--output",                "json"
    )
    $jsonOutput     = az @cliParams
    $creationResult = $jsonOutput | ConvertFrom-Json

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
        continue
    }

    Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan
    az account management-group subscription add `
        --name         $($s.MG) `
        --subscription $creationResult.id

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done provisioning subscriptions and assigning them into MGs." -ForegroundColor Yellow
