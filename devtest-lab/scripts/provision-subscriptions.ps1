# File: scripts/provision-subscriptions.ps1
# Purpose: Create Pay-As-You-Go subscriptions and assign them into your new Management Groups

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match your environment
# ───────────────────────────────────────────────────────────────────────────────
$billingAccountName   = "a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30" 
$billingProfileName   = "6RX4-VIIG-BG7-PGB"   # (Output from: az billing profile list --account-name <billingAccountName>)
$paogSkuId            = "C0EF4307-CCD7-4B2A-B9B0-6D8352EE9A21"  # Pay-As-You-Go SKU (example GUID)

# Define which subscriptions to create and what MG they belong under:
$subsToCreate = @(
  @{ Name = "Management-Sub";       DisplayName = "Management-Subscription";       MG = "Management-MG" },
  @{ Name = "Identity-Sub";         DisplayName = "Identity-Subscription";         MG = "Identity-MG" },
  @{ Name = "Connectivity-Sub";     DisplayName = "Connectivity-Subscription";     MG = "Connectivity-MG" },
  @{ Name = "LandingZone-P1-Sub";   DisplayName = "LandingZone-Prod-Subscription";   MG = "Landing-Zones-MG" },
  @{ Name = "LandingZone-A2-Sub";   DisplayName = "LandingZone-PreProd-Subscription";MG = "Landing-Zones-MG" },
  @{ Name = "Sandbox-Sub";          DisplayName = "Sandbox-Subscription";          MG = "Sandbox-MG" }
)

# ───────────────────────────────────────────────────────────────────────────────
# 2. Loop through each subscription, create it, pause, then assign to MG
# ───────────────────────────────────────────────────────────────────────────────
foreach ($s in $subsToCreate) {
  Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan

  # Kick off subscription creation (returns JSON with .id property)
  $creationResult = az billing subscription create `
    --account-name      $billingAccountName `
    --profile-name      $billingProfileName `
    --subscription-name $($s.Name) `
    --sku-id            $paogSkuId `
    --location          eastus `
    --output            json | ConvertFrom-Json

  if (-not $creationResult.id) {
    Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
    continue
  }

  Write-Host "✔ Requested sub ID: $($creationResult.id)" -ForegroundColor Green

  # Short delay to allow Azure to finish creating
  Start-Sleep -Seconds 15

  Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan
  az account management-group subscription add `
    --name $($s.MG) `
    --subscription $creationResult.id

  Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
  Write-Host ""
}

Write-Host "✅ All done provisioning subscriptions and assigning them into MGs." -ForegroundColor Yellow
