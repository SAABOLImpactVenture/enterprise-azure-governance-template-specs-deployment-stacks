// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// === Prompt: Import GovernanceRegistry to link on-chain parameter store ===
import "./GovernanceRegistry.sol";
// === Prompt: Import and alias OZ’s AccessControl for battle-tested role logic ===
import { AccessControl as OZAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title AccessControl
/// @dev Inherits from OpenZeppelin’s AccessControl to manage roles, with integration to our GovernanceRegistry.
contract AccessControl is OZAccessControl {
    // === Prompt: Expose the linked governance registry for on-chain parameter checks ===
    GovernanceRegistry public governanceRegistry;
    
    // === Prompt: Define our enterprise roles ===
    bytes32 public constant ADMIN_ROLE    = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUDITOR_ROLE  = keccak256("AUDITOR_ROLE");
    
    /// @dev Constructor sets the governance registry and bootstraps ADMIN_ROLE  
    /// @prompt Assign ADMIN_ROLE to deployer; configure role hierarchy
    constructor(address _governanceRegistry) {
        require(_governanceRegistry != address(0), "AccessControl: governance registry is zero address");
        governanceRegistry = GovernanceRegistry(_governanceRegistry);
        
        // === Prompt: Grant the deployer ADMIN_ROLE and make it the admin of all roles ===
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE,    ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(AUDITOR_ROLE,  ADMIN_ROLE);
    }
    
    /// @notice Grants a specific role to an account  
    /// @dev Only callable by ADMIN_ROLE; delegates to OZ’s logic  
    /// @prompt Ensure only ADMIN_ROLE can call, and emit standard OZ events
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        super.grantRole(role, account);
    }
    
    /// @notice Revokes a specific role from an account  
    /// @dev Only callable by ADMIN_ROLE; delegates to OZ’s logic  
    /// @prompt Mirror grantRole pattern for revoking with correct access check
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        super.revokeRole(role, account);
    }
    
    /// @dev `hasRole` and all internal mappings/events are inherited from OZAccessControl  
    /// @prompt No custom mapping needed—rely on well-tested base implementation
    
    // (no custom _grantRole/_revokeRole functions—OZ provides them)
}
