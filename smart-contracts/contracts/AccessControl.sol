// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GovernanceRegistry.sol";

/**
 * @title AccessControl
 * @dev Contract for managing role-based access control in the enterprise solution.
 */
contract AccessControl {
    // Reference to the governance registry
    GovernanceRegistry public governanceRegistry;
    
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    
    // Mapping of role assignments
    mapping(bytes32 => mapping(address => bool)) private roles;
    
    // Events
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    /**
     * @dev Constructor sets the governance registry address and assigns admin role to sender
     * @param _governanceRegistry Address of the governance registry
     */
    constructor(address _governanceRegistry) {
        require(_governanceRegistry != address(0), "AccessControl: governance registry is zero address");
        governanceRegistry = GovernanceRegistry(_governanceRegistry);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev Modifier to restrict function access to role holders
     * @param role The role required
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: caller does not have the required role");
        _;
    }
    
    /**
     * @dev Grants a role to an account
     * @param role The role being granted
     * @param account The account receiving the role
     */
    function grantRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }
    
    /**
     * @dev Revokes a role from an account
     * @param role The role being revoked
     * @param account The account losing the role
     */
    function revokeRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }
    
    /**
     * @dev Checks if an account has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return True if the account has the role
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[role][account];
    }
    
    /**
     * @dev Internal function to grant a role
     * @param role The role to grant
     * @param account The account receiving the role
     */
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }
    
    /**
     * @dev Internal function to revoke a role
     * @param role The role to revoke
     * @param account The account losing the role
     */
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}