#!/bin/bash

# ===================================================================================
# Azure Subscription to Management Group Assignment Tool
# ===================================================================================
# 
# Current Date/Time (UTC): 2025-06-06 15:22:54
# Current User: GEP-V
# Environment: GitHub Codespace
#
# PURPOSE:
#   This script automates the assignment of Azure subscriptions to appropriate 
#   management groups within an Azure tenant. It handles installation of the Azure CLI
#   if needed, authentication, and the assignment process itself.
#
# CODESPACE USAGE INSTRUCTIONS:
#   1. Create this file in your GitHub Codespace
#   2. Make it executable: chmod +x assign-subscriptions.sh
#   3. Run it: ./assign-subscriptions.sh
#   4. Follow the authentication prompts when they appear
#
# AI PROMPT ENGINEERING NOTES:
#   - This script was created with help from GitHub Copilot
#   - Key prompt elements that helped generate this solution:
#     * Specifying the exact environment (GitHub Codespace)
#     * Providing exact subscription IDs and management group names
#     * Mentioning the "-MG" suffix issue with management group names
#     * Requesting error handling and verification steps
#   - The final solution required multiple iterations to handle:
#     * Installing Azure CLI in a Codespace environment
#     * Management group name format corrections
#     * Authentication flow appropriate for headless environments
#
# TROUBLESHOOTING:
#   - If 'az not found' errors occur, the script will attempt to install Azure CLI
#   - If management groups aren't found, verify their exact names with the list command
#   - Authentication errors typically require interactive login through device code flow
# ===================================================================================

# Colors for better output - helps visually distinguish different types of messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script header with identifying information
echo -e "${YELLOW}Azure Subscription to Management Group Assignment Tool${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo -e "${CYAN}Current Date/Time (UTC): 2025-06-06 15:22:54${NC}"
echo -e "${CYAN}User: GEP-V${NC}"
echo -e "${CYAN}Environment: GitHub Codespace${NC}"
echo ""

# ==== SECTION 1: ENVIRONMENT SETUP ====
# Check if Azure CLI is installed - this is critical for GitHub Codespaces
# which may not have Azure CLI pre-installed
if ! command -v az &> /dev/null; then
    echo -e "${YELLOW}Azure CLI not found. Installing...${NC}"
    
    # Install Azure CLI using the official Microsoft installation script
    # This approach works well in Ubuntu-based Codespace environments
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

# ==== SECTION 2: AUTHENTICATION ====
# Login to Azure using device code flow, which works well in terminal environments
# like GitHub Codespaces where browser-based auth might not be available
echo -e "${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to Azure. Please try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully logged in to Azure!${NC}"

# ==== SECTION 3: DISCOVERY AND CONFIGURATION ====
# List available subscriptions to verify our access and confirm IDs
echo -e "${YELLOW}Available subscriptions:${NC}"
az account list --output table

# Define subscription IDs - these were discovered in previous runs
# AI PROMPT NOTE: When generating scripts like this, always provide actual IDs
MANAGEMENT_SUB_ID="c0b5b2a1-3e7b-46a4-9c0f-359b663ed31f"
IDENTITY_SUB_ID="2a931799-daea-4d93-94f8-0244704b5d06"
CONNECTIVITY_SUB_ID="cbd07569-930e-4b91-93b2-e6e87bdf02ed"
LANDINGZONE_P1_SUB_ID="0982688a-6198-414f-aecd-0a55776bbfd0"
LANDINGZONE_A2_SUB_ID="00bf28e6-523a-432b-8840-3c572cf4e12e"

# List available management groups to see their actual names
# This was a critical step to discover the actual naming convention with -MG suffix
echo -e "${YELLOW}Available management groups:${NC}"
az account management-group list --output table

# Management group names with correct suffix format
# AI PROMPT NOTE: The key insight was recognizing the naming convention difference
MANAGEMENT_MG="Management-MG"
IDENTITY_MG="Identity-MG"
CONNECTIVITY_MG="Connectivity-MG"
LANDING_ZONES_MG="Landing-Zones-MG"
SANDBOX_MG="Sandbox-MG"

# ==== SECTION 4: HELPER FUNCTIONS ====
# Function to check if management group exists before attempting assignment
# This prevents errors when trying to assign to non-existent groups
check_mg_exists() {
    local mg_name=$1
    local exists=$(az account management-group list --query "[?name=='$mg_name'] | length(@)" --output tsv)
    
    if [ "$exists" -eq "1" ]; then
        echo -e "${GREEN}Management group '$mg_name' exists.${NC}"
        return 0
    else
        echo -e "${RED}Management group '$mg_name' does not exist!${NC}"
        return 1
    fi
}

# Function to assign subscription to management group
# Handles the actual assignment operation with proper error checking
assign_subscription() {
    local subscription_id=$1
    local management_group=$2
    local subscription_name=$3
    
    # First check if the management group exists
    if ! check_mg_exists "$management_group"; then
        echo -e "${RED}Skipping assignment for $subscription_name due to missing management group.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}▸ Assigning subscription ${subscription_name} (${subscription_id}) to management group: ${management_group}${NC}"
    
    # Execute the Azure CLI command to assign the subscription
    az account management-group subscription add --name "${management_group}" --subscription "${subscription_id}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully assigned subscription to management group '${management_group}'.${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to assign subscription to management group '${management_group}'.${NC}"
        return 1
    fi
}

# ==== SECTION 5: SUBSCRIPTION ASSIGNMENT ====
# Track successful assignments for reporting
SUCCESS_COUNT=0
TOTAL_ASSIGNMENTS=5

# Assign each subscription to its appropriate management group
# AI PROMPT NOTE: Breaking operations into discrete steps makes debugging easier

# Management subscription
if assign_subscription "${MANAGEMENT_SUB_ID}" "${MANAGEMENT_MG}" "Management-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Identity subscription
if assign_subscription "${IDENTITY_SUB_ID}" "${IDENTITY_MG}" "Identity-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Connectivity subscription
if assign_subscription "${CONNECTIVITY_SUB_ID}" "${CONNECTIVITY_MG}" "Connectivity-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Landing Zone P1 subscription
if assign_subscription "${LANDINGZONE_P1_SUB_ID}" "${LANDING_ZONES_MG}" "LandingZone-P1-Sub"; then
    ((SUCCESS_COUNT++))
fi

# Landing Zone A2 subscription
if assign_subscription "${LANDINGZONE_A2_SUB_ID}" "${LANDING_ZONES_MG}" "LandingZone-A2-Sub"; then
    ((SUCCESS_COUNT++))
fi

# ==== SECTION 6: RESULTS SUMMARY ====
# Provide a clear summary of what happened
echo -e "${YELLOW}Assignment Summary:${NC}"
echo -e "${YELLOW}Successfully assigned ${SUCCESS_COUNT} out of ${TOTAL_ASSIGNMENTS} subscriptions${NC}"

if [ "${SUCCESS_COUNT}" -eq "${TOTAL_ASSIGNMENTS}" ]; then
    echo -e "${GREEN}✅ All subscriptions successfully assigned to management groups!${NC}"
else
    echo -e "${YELLOW}⚠️ Some subscription assignments failed. Please review the logs above.${NC}"
fi

# ==== ADDITIONAL NOTES ====
# This script demonstrates several key patterns for Azure automation:
# 1. Environment detection and setup (Azure CLI installation)
# 2. Authentication handling appropriate for the environment
# 3. Discovery of resources before attempting operations
# 4. Verification steps to prevent errors
# 5. Clear error handling and reporting
# 6. Idempotent operations that can be run multiple times safely
#
# The most important insight was identifying the naming convention difference
# between the expected management group names and the actual names with -MG suffix.
#
# AI PROMPT TIP: When working with cloud resources, always include a discovery/verification
# step before attempting modifications, as naming conventions and IDs may differ
# from expectations.
