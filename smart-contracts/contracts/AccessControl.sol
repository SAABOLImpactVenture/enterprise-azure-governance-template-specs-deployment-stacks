// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GovernanceRegistry.sol";
import { AccessControl as OZAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title AccessControl
/// @dev Inherits from OpenZeppelin’s AccessControl to manage roles, with integration to our GovernanceRegistry.
contract AccessControl is OZAccessControl {
    // Reference to the governance registry for on-chain parameter checks
    GovernanceRegistry public governanceRegistry;
    
    // Define enterprise roles
    bytes32 public constant ADMIN_ROLE    = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUDITOR_ROLE  = keccak256("AUDITOR_ROLE");
    
    /// @dev Constructor sets the governance registry and bootstraps ADMIN_ROLE
    /// @param _governanceRegistry Address of the governance registry
    constructor(address _governanceRegistry) {
        require(
            _governanceRegistry != address(0),
            "AccessControl: governance registry is zero address"
        );
        governanceRegistry = GovernanceRegistry(_governanceRegistry);
        
        // Grant deployer the ADMIN_ROLE and set up role hierarchy
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE,    ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(AUDITOR_ROLE,  ADMIN_ROLE);
    }
    
    /// @notice Grants a specific role to an account
    /// @dev Only callable by ADMIN_ROLE; delegates to OZ’s logic
    /// @param role The role to grant
    /// @param account The account receiving the role
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        super.grantRole(role, account);
    }
    
    /// @notice Revokes a specific role from an account
    /// @dev Only callable by ADMIN_ROLE; delegates to OZ’s logic
    /// @param role The role to revoke
    /// @param account The account losing the role
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        super.revokeRole(role, account);
    }
    
    // `hasRole`, `supportsInterface`, and all internal grant/revoke logic
    // are inherited from OZAccessControl.
}
