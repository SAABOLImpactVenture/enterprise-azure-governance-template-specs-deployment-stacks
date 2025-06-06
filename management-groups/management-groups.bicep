/*
============================================================
Azure Management Group Hierarchy for Enterprise Scale Landing Zone
============================================================
Current Date and Time (UTC): 2025-06-06 19:17:57
Current User's Login: GEP-V

DESCRIPTION:
This Bicep template creates a management group hierarchy aligned with 
Azure Enterprise Scale Landing Zone (ESLZ) architecture. It creates a root
management group with five child management groups representing different
workload categories and management functions.

PROMPT ENGINEERING NOTES:
When asking AI to generate or modify Bicep templates for Azure management 
groups, consider the following best practices:

1. Specify target scope upfront - 'tenant' scope is required for management 
   groups, and this is a common source of errors if omitted.

2. Be explicit about naming conventions:
   - Include the -MG suffix in the resource names (not just display names)
   - This allows automation scripts to reliably identify management groups

3. Clearly distinguish between 'name' (the resource identifier) and 
   'displayName' (the human-readable label) in your prompts

4. For parent-child relationships, be specific about the hierarchy depth
   and how the parent ID is referenced

5. Request parameterization of names to allow flexibility in deployment
   across different environments
*/

// Setting tenant scope is critical for management group operations
// AI PROMPT TIP: Always specify this first when asking for management group templates
targetScope = 'tenant'

// Parameters for management group names
// AI PROMPT TIP: When requesting parameterized Bicep templates, ask for default values
// that follow your organization's naming conventions
param rootName               string = 'Platform-MG'
param managementChildName    string = 'Management-MG'
param identityChildName      string = 'Identity-MG'
param connectivityChildName  string = 'Connectivity-MG'
param landingZonesChildName  string = 'Landing-Zones-MG'
param sandboxChildName       string = 'Sandbox-MG'

// Root management group
// AI PROMPT TIP: Request consistent structure for all resources of the same type
// to improve template readability and maintainability
resource rootMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: rootName // This MUST be unique across the entire tenant
  properties: {
    displayName: 'Platform Management Group' // Human-readable name shown in portal
    details: {}
  }
}

// Management child group - For shared services management resources
// AI PROMPT TIP: Ask for comments that explain the purpose of each management group
// to document the intended use case
resource mgManagement 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: managementChildName
  properties: {
    displayName: 'Management' // Shorter display name for portal view
    details: {
      parent: {
        // Reference the parent management group ID
        // AI PROMPT TIP: Always specify the parent-child relationship explicitly
        id: rootMG.id
      }
    }
  }
}

// Identity child group - For identity management resources
// Such as AD DS, AD FS, or Azure AD Premium workloads
resource mgIdentity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: identityChildName
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

// Connectivity child group - For connectivity resources
// Such as ExpressRoute, VPN, Azure Firewall resources
resource mgConnectivity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: connectivityChildName
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

// Landing Zones child group - For application workloads
// Production and non-production application environments
resource mgLandingZones 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: landingZonesChildName
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

// Sandbox child group - For testing and exploration
// Isolated environment with fewer restrictions for innovation
resource mgSandbox 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: sandboxChildName
  properties: {
    displayName: 'Sandbox'
    details: {
      parent: {
        id: rootMG.id
      }
    }
  }
}

/*
DEPLOYMENT CONSIDERATIONS:
1. This template requires Owner or Management Group Contributor role at the tenant root
2. First deployment may take 15-30 minutes to complete as management group creation
   is an asynchronous operation
3. Management groups must have globally unique names within the tenant
4. There's a limit of 10,000 management groups per tenant
5. Management group hierarchy can be up to 6 levels deep (including root)
6. Consider adding outputs to return the management group IDs for use in subsequent
   deployments, such as policy assignments

COMMON ERRORS:
- "InvalidTargetScope": Ensure targetScope is set to 'tenant'
- "ParentNotFound": Ensure parent management group exists before creating children
- "InvalidManagementGroupId": Ensure management group names follow Azure naming rules
  (alphanumeric, hyphens, underscores, no spaces, 1-90 characters)

AI PROMPT TIP: When troubleshooting Bicep deployment issues, provide the exact error
message and which resource is causing the problem
*/
