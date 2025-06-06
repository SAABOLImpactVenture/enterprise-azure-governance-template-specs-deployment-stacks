# ===============================================================
# Azure DevTest Lab VM Deployment Workflow
# ===============================================================
# Last Updated: 2025-06-06 20:15:55 UTC
# Current User: GEP-V
#
# DESCRIPTION:
# This workflow deploys and configures a VM in Azure DevTest Lab
# with security hardening and monitoring enabled.
# ===============================================================

name: Deploy DevTest Lab VM

on:
  push:
    branches:
      - main
    paths:
      - 'devtest-lab/**'
  # Add manual trigger option
  workflow_dispatch:
    inputs:
      vm_size:
        description: 'VM Size'
        required: false
        default: 'Standard_B2s'
        type: choice
        options:
          - Standard_B2s
          - Standard_D2s_v3
          - Standard_D4s_v3
      environment:
        description: 'Deployment environment'
        required: false
        default: 'devtest'
        type: choice
        options:
          - devtest
          - staging

env:
  # These secrets must already exist in GitHub → Settings → Secrets → Actions
  AZURE_TENANT_ID:      ${{ secrets.AZURE_TENANT_ID }}         # Your Azure AD Tenant ID
  AZURE_OIDC_CLIENT_ID: ${{ secrets.AZURE_OIDC_CLIENT_ID }}    # Client ID of your App Registration (federated SP)
  TARGET_SUBSCRIPTION:  ${{ secrets.LANDING_A2_SUB_ID }}       # Subscription ID where DevTest Lab lives
  TARGET_RG:            "rg-devtest-lab"                       # Name of the Resource Group for DevTest Lab
  DEPLOYMENT_NAME:      "devtest-vm-${{ github.run_id }}"      # Unique deployment name

jobs:
  deploy-devtest:
    runs-on: ubuntu-latest
    # Add timeout to prevent hanging jobs
    timeout-minutes: 30
    
    # Optional environment protection
    environment: ${{ github.event.inputs.environment || 'devtest' }}
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Get full history for auditing

      - name: Setup Parameters
        id: setup
        run: |
          echo "Starting DevTest VM deployment at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
          
          # Create a working copy of the parameters file
          cp devtest-lab/parameters/devtest-vm.parameters.json devtest-lab/parameters/devtest-vm.parameters.processed.json
          
          # Create safe replacement files to avoid issues with special characters
          echo '${{ secrets.SSH_PUBLIC_KEY }}' > ssh_key.txt
          echo '${{ secrets.LANDING_A2_SUB_ID }}' > sub_id.txt
          
          # Method 1: Use safer file-based replacements with awk
          awk -v ssh_key="$(cat ssh_key.txt)" '{gsub(/\${SSH_PUBLIC_KEY}/, ssh_key); print}' devtest-lab/parameters/devtest-vm.parameters.processed.json > temp1.json
          awk -v sub_id="$(cat sub_id.txt)" '{gsub(/\${LANDING_A2_SUB_ID}/, sub_id); print}' temp1.json > devtest-lab/parameters/devtest-vm.parameters.processed.json
          
          # Apply workflow dispatch VM size parameter if provided
          if [ "${{ github.event_name }}" == "workflow_dispatch" ] && [ -n "${{ github.event.inputs.vm_size }}" ]; then
            echo "Using custom VM size: ${{ github.event.inputs.vm_size }}"
            
            # Use jq to modify the VM size parameter
            jq --arg vmsize "${{ github.event.inputs.vm_size }}" '.parameters.vmSize.value = $vmsize' \
              devtest-lab/parameters/devtest-vm.parameters.processed.json > temp2.json
              
            mv temp2.json devtest-lab/parameters/devtest-vm.parameters.processed.json
            
            echo "Modified parameters with custom VM size"
          fi
          
          # Set the processed parameters file as the one to use
          echo "PARAMS_FILE=devtest-lab/parameters/devtest-vm.parameters.processed.json" >> $GITHUB_ENV
          
          # Clean up temp files
          rm -f ssh_key.txt sub_id.txt temp1.json temp2.json
          
          echo "✅ Parameters file prepared with secrets and customizations"
          
          # Validate the parameters file has proper JSON structure (but don't display contents with secrets)
          if jq empty devtest-lab/parameters/devtest-vm.parameters.processed.json; then
            echo "✅ Parameters file validated as valid JSON"
          else
            echo "❌ Parameters file is not valid JSON. Aborting."
            exit 1
          fi

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id:                ${{ env.AZURE_OIDC_CLIENT_ID }}
          tenant-id:                ${{ env.AZURE_TENANT_ID }}
          subscription-id:          ${{ env.TARGET_SUBSCRIPTION }}
          allow-no-subscriptions:   false

      - name: Validate Bicep Template
        id: validate
        run: |
          echo "Validating DevTest Lab Bicep template..."
          az deployment group validate \
            --resource-group ${{ env.TARGET_RG }} \
            --template-file devtest-lab/devtest-vm.bicep \
            --parameters @${{ env.PARAMS_FILE }}
          echo "✅ Template validation successful"

      - name: Deploy DevTest Lab Bicep
        id: deploy
        run: |
          echo "Deploying DevTest Lab VM..."
          # Note the @ symbol before ${{ env.PARAMS_FILE }} to properly read the file
          az deployment group create \
            --name "${{ env.DEPLOYMENT_NAME }}" \
            --resource-group ${{ env.TARGET_RG }} \
            --template-file devtest-lab/devtest-vm.bicep \
            --parameters @${{ env.PARAMS_FILE }}
          
          # Save VM name and other outputs for use in later steps
          VM_NAME=$(az deployment group show \
            --name "${{ env.DEPLOYMENT_NAME }}" \
            --resource-group ${{ env.TARGET_RG }} \
            --query "properties.outputs.vmName.value" -o tsv)
          
          echo "VM_NAME=$VM_NAME" >> $GITHUB_ENV
          echo "✅ Deployment successful. VM Name: $VM_NAME"

      - name: Configure Just-In-Time Access
        id: jit
        run: |
          echo "Configuring Just-In-Time Access for VM: ${{ env.VM_NAME }}..."
          pwsh -Command "./devtest-lab/scripts/enable-jit.ps1 -VMName '${{ env.VM_NAME }}' -ResourceGroup '${{ env.TARGET_RG }}'" 
          echo "✅ JIT Access configured"

      - name: Configure NSG Hardening
        id: nsg
        run: |
          echo "Applying NSG hardening rules..."
          pwsh -Command "./devtest-lab/scripts/configure-nsg.ps1 -VMName '${{ env.VM_NAME }}' -ResourceGroup '${{ env.TARGET_RG }}'"
          echo "✅ NSG hardening applied"

      - name: Enable Diagnostics
        id: diag
        run: |
          echo "Enabling diagnostics and monitoring..."
          pwsh -Command "./devtest-lab/scripts/enable-diagnostics.ps1 -VMName '${{ env.VM_NAME }}' -ResourceGroup '${{ env.TARGET_RG }}'"
          echo "✅ Diagnostics enabled"

      - name: Clean Up Sensitive Files
        if: always()
        run: |
          # Remove any files with secrets to prevent leaking in logs/caches
          echo "Cleaning up sensitive parameter files..."
          rm -f devtest-lab/parameters/devtest-vm.parameters.processed.json
          rm -f devtest-lab/parameters/devtest-vm.parameters.temp.json
          rm -f devtest-lab/parameters/devtest-vm.parameters.modified.json
          rm -f temp*.json
          echo "✅ Sensitive files removed"

      - name: Report Success
        if: success()
        run: |
          echo "✅ DevTest VM deployment completed successfully at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
          echo "VM Name: ${{ env.VM_NAME }}"
          echo "Resource Group: ${{ env.TARGET_RG }}"
          echo "Deployment: ${{ env.DEPLOYMENT_NAME }}"
          
          # Create a summary in GitHub's UI
          cat > $GITHUB_STEP_SUMMARY << EOF
          ## DevTest VM Deployment Summary
          
          | Resource | Value |
          | --- | --- |
          | VM Name | ${{ env.VM_NAME }} |
          | Resource Group | ${{ env.TARGET_RG }} |
          | Subscription | A2 Landing Zone |
          | Deployment Name | ${{ env.DEPLOYMENT_NAME }} |
          | VM Size | $(az deployment group show --name "${{ env.DEPLOYMENT_NAME }}" --resource-group ${{ env.TARGET_RG }} --query "properties.parameters.vmSize.value" -o tsv) |
          | Completed At | $(date -u +'%Y-%m-%d %H:%M:%S UTC') |
          
          ### Security Features Enabled
          
          - ✅ Just-In-Time Access
          - ✅ NSG Hardening
          - ✅ Diagnostics & Monitoring
          - ✅ SSH Key Authentication
          EOF

      - name: Report Failure
        if: failure()
        run: |
          echo "❌ DevTest VM deployment failed at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
          echo "Please check the logs for detailed error information."
          
          # Create a failure summary
          cat > $GITHUB_STEP_SUMMARY << EOF
          ## ❌ DevTest VM Deployment Failed
          
          Deployment failed at $(date -u +'%Y-%m-%d %H:%M:%S UTC')
          
          ### Troubleshooting Steps
          
          1. Check if SSH_PUBLIC_KEY secret is properly configured
          2. Verify Azure credentials and permissions
          3. Confirm resource quotas in subscription
          4. Review template validation errors above
          
          [View run logs](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})
          EOF