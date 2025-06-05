<#
    File: scripts/provision-subscriptions.ps1
    Purpose: Create Pay-As-You-Go subscriptions via `az account subscription create`
             and assign them immediately into Management Groups.

    NOTES:
    • The service principal (SP) you run this as must have:
        – “Billing Reader” on the EXACT invoice section 
          (/providers/Microsoft.Billing/billingAccounts/<...>/billingProfiles/<...>/invoiceSections/A3HN-2BWX-PJA-PGB),
        – “Management Group Contributor” on each target MG,
        – “User Access Administrator” (or Owner) at the tenant root (/) so it can assign subscriptions into MGs.
#>

# ───────────────────────────────────────────────────────────────────────────────
# 1. Update these variables to match your environment
# ───────────────────────────────────────────────────────────────────────────────

# Full resource ID of the invoice section, e.g.:
# "/providers/Microsoft.Billing/billingAccounts/a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30
#  /billingProfiles/6RX4-VIIG-BG7-PGB/invoiceSections/A3HN-2BWX-PJA-PGB"

$invoiceSectionResourceId = "/providers/Microsoft.Billing/billingAccounts/a80e6778-82d5-5afe-27fc-678a41b69836:1f1915a2-2b3d-44f4-aac0-e08a28c18d27_2018-09-30/billingProfiles/6RX4-VIIG-BG7-PGB/invoiceSections/A3HN-2BWX-PJA-PGB"

# ───────────────────────────────────────────────────────────────────────────────
# 2. Define which subscriptions to create & which Management Group to place them under
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
# 3. Loop through each subscription, create it, then assign into its MG
# ───────────────────────────────────────────────────────────────────────────────

foreach ($s in $subsToCreate) {

    Write-Host "▸ Creating subscription: $($s.Name)" -ForegroundColor Cyan

    # Use 'az account subscription create' from the 'account' extension (preview).
    $creationJson = az account subscription create `
        --subscription-name   $($s.Name) `
        --offer-type          "Pay-As-You-Go" `
        --billing-scope       $invoiceSectionResourceId `
        --output              "json"

    $creationResult = $creationJson | ConvertFrom-Json

    if (-not $creationResult.id) {
        Write-Error "X Failed to create subscription '$($s.Name)' – no ID returned."
        continue
    }

    Write-Host "✔ Created sub ID: $($creationResult.id)" -ForegroundColor Green

    # Give Azure a moment to finish provisioning the subscription
    Start-Sleep -Seconds 15

    Write-Host "▸ Assigning '$($s.Name)' to MG '$($s.MG)'" -ForegroundColor Cyan

    az account management-group subscription add `
        --name         $($s.MG) `
        --subscription $creationResult.id

    Write-Host "✔ Assigned $($s.Name) → $($s.MG)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "✅ All done! Subscriptions created & assigned into Management Groups." -ForegroundColor Yellow
