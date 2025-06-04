# File: .github/workflows/provision-all.yml
name: Provision All Subscriptions

# Triggering via workflow_dispatch allows you to run it manually from the Actions tab.
on:
  workflow_dispatch:

env:
  # These secrets must already be created under your repo's Settings → Secrets → Actions:
  AZURE_TENANT_ID:      ${{ secrets.AZURE_TENANT_ID }}         # Your Azure AD tenant ID
  AZURE_OIDC_CLIENT_ID: ${{ secrets.AZURE_OIDC_CLIENT_ID }}    # Client ID of the App Registration (federated SP)
  MANAGEMENT_SUB_ID:    ${{ secrets.MANAGEMENT_SUB_ID }}       # Any subscription where the SP has permission to create new subs (User Access Admin at "/" scope)

jobs:
  provision-all-subs:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Azure Login via OIDC
        uses: azure/login@v1
        with:
          # If you are using an OIDC‐federated App Registration, pass in client-id & tenant-id:
          client-id:               ${{ env.AZURE_OIDC_CLIENT_ID }}
          tenant-id:               ${{ env.AZURE_TENANT_ID }}
          subscription-id:         ${{ env.MANAGEMENT_SUB_ID }}
          allow-no-subscriptions:  true
          auth-type:               SERVICE_PRINCIPAL
          audience:                api://AzureADTokenExchange
          subject:                 repo:SAABOLImpactVenture/enterprise-azure-governance-template-specs-deployment-stacks:ref:refs/heads/main

          # ——— OR ———
          # If you prefer to use a classic (client-secret) Service Principal instead of OIDC,
          # comment out the above lines and uncomment these:
          # client-id:             ${{ secrets.CLASSIC_SP_CLIENT_ID }}
          # client-secret:         ${{ secrets.CLASSIC_SP_CLIENT_SECRET }}
          # tenant-id:             ${{ secrets.AZURE_TENANT_ID }}
          # subscription-id:       ${{ secrets.MANAGEMENT_SUB_ID }}

      - name: Run provision-subscriptions.ps1
        shell: pwsh
        run: |
          # Change into the scripts folder where provision-subscriptions.ps1 lives
          cd ./scripts

          # Execute the provisioning script. It will:
          #   • Create each Pay-As-You-Go subscription under your billing profile/account
          #   • Wait a few seconds
          #   • Assign the new subscription into its designated Management Group
          pwsh ./provision-subscriptions.ps1

      - name: Confirm completion
        run: echo "✅ All subscriptions should now be created and assigned to their Management Groups."
