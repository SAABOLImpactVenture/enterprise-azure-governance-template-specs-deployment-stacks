#!/bin/bash

# Script to install Azure CLI and assign subscriptions to management groups
# Created: 2025-06-06 14:54:09
# Author: GEP-V
# Environment: GitHub Codespace

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Azure Subscription to Management Group Assignment Tool${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo -e "${CYAN}Current Date/Time: 2025-06-06 14:54:09${NC}"
echo -e "${CYAN}User: GEP-V${NC}"
echo -e "${CYAN}Environment: GitHub Codespace${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${YELLOW}Azure CLI not found. Installing...${NC}"
    
    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Azure CLI. Please install it manually.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Azure CLI installed successfully!${NC}"
else
    echo -e "${GREEN}Azure CLI is already installed.${NC}"
    az --version | head -n 1
fi

# Login to Azure
echo -e "${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to Azure. Please try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully logged in to Azure!${NC}"

# List available subscriptions
echo -e "${YELLOW}Available subscriptions:${NC}"
az account list --output table

# Define subscription IDs
MANAGEMENT_SUB_ID="c0b5b2a1-3e7b-46a4-9c0f-359b663ed31f"
IDENTITY_SUB_ID="2a931799-daea-4d93-94f8-0244704b5d06"
CONNECTIVITY_SUB_ID="cbd07569-930e-4b91-93b2-e6e87bdf02ed"
LANDINGZONE_P1_SUB_ID="0982688a-6198-414f-aecd-0a55776bbfd0"
LANDINGZONE_A2_SUB_ID="00bf28e6-523a-432b-8840-3c572cf4e12e"

# List available management groups
echo -e "${YELLOW}Available management groups:${NC}"
az account management-group list --output table

# Function to assign subscription to management group
assign_subscription() {
    local subscription_id=$1
    local management_group=$2
    local subscription_name=$3
    
    echo -e "${CYAN}▸ Assigning subscription ${subscription_name} (${subscription_id}) to management group: ${management_group}${NC}"
    
    az account management-group subscription add --name "${management_group}" --subscription "${subscription_id}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully assigned subscription to management group '${management_group}'.${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to assign subscription to management group '${management_group}'.${NC}"
        return 1
    fi
}

# Assign subscriptions to management groups
SUCCESS_COUNT=0
TOTAL_ASSIGNMENTS=5

# Management subscription
if assign_subscription "${MANAGEMENT_SUB_ID}" "Management" "Management-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Identity subscription
if assign_subscription "${IDENTITY_SUB_ID}" "Identity" "Identity-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Connectivity subscription
if assign_subscription "${CONNECTIVITY_SUB_ID}" "Connectivity" "Connectivity-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Landing Zone P1 subscription
if assign_subscription "${LANDINGZONE_P1_SUB_ID}" "Landing-Zones" "LandingZone-P1-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Landing Zone A2 subscription
if assign_subscription "${LANDINGZONE_A2_SUB_ID}" "Landing-Zones" "LandingZone-A2-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Output summary
echo -e "${YELLOW}Assignment Summary:${NC}"
echo -e "${YELLOW}Successfully assigned ${SUCCESS_COUNT} out of ${TOTAL_ASSIGNMENTS} subscriptions${NC}"

if [ "${SUCCESS_COUNT}" -eq "${TOTAL_ASSIGNMENTS}" ]; then
    echo -e "${GREEN}✅ All subscriptions successfully assigned to management groups!${NC}"
else
    echo -e "${YELLOW}⚠️ Some subscription assignments failed. Please review the logs above.${NC}"
fi

echo -e "${CYAN}Subscription IDs:${NC}"
echo -e "${CYAN}Management-Sub: ${MANAGEMENT_SUB_ID}${NC}"
echo -e "${CYAN}Identity-Sub: ${IDENTITY_SUB_ID}${NC}"
echo -e "${CYAN}Connectivity-Sub: ${CONNECTIVITY_SUB_ID}${NC}"
echo -e "${CYAN}LandingZone-P1-Sub: ${LANDINGZONE_P1_SUB_ID}${NC}"
echo -e "${CYAN}LandingZone-A2-Sub: ${LANDINGZONE_A2_SUB_ID}${NC}"
