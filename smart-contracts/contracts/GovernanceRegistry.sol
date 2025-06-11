// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title GovernanceRegistry
/// @dev Registry for governance parameters and authorized entities in the enterprise solution.
contract GovernanceRegistry {
    /// @dev Owner of the registry
    address public owner;
    
    /// @dev Mapping of governance parameters
    mapping(bytes32 => string) private parameters;
    
    /// @dev Mapping of authorized entities
    mapping(address => bool) public authorizedEntities;
    
    /// @dev Emitted when a parameter is updated on-chain
    event ParameterSet(bytes32 indexed key, string value);
    
    /// @dev Emitted when an entity’s authorization status changes
    event EntityAuthorized(address indexed entity, bool status);
    
    /// @dev Emitted when ownership of the registry transfers
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /// @dev Constructor sets the original owner and auto-authorizes them
    constructor() {
        owner = msg.sender;
        authorizedEntities[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /// @dev Modifier to restrict access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "GovernanceRegistry: caller is not the owner");
        _;
    }
    
    /// @dev Modifier to restrict access to authorized entities
    modifier onlyAuthorized() {
        require(authorizedEntities[msg.sender], "GovernanceRegistry: caller is not authorized");
        _;
    }
    
    /// @notice Transfers ownership of the registry
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "GovernanceRegistry: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /// @notice Sets the authorization status of an entity
    /// @param entity The address of the entity
    /// @param status The authorization status
    function setEntityAuthorization(address entity, bool status) public onlyOwner {
        authorizedEntities[entity] = status;
        emit EntityAuthorized(entity, status);
    }
    
    /// @notice Sets a governance parameter
    /// @param key The parameter key
    /// @param value The parameter value
    function setParameter(bytes32 key, string memory value) public onlyAuthorized {
        parameters[key] = value;
        emit ParameterSet(key, value);
    }
    
    /// @notice Gets a governance parameter
    /// @param key The parameter key
    /// @return The parameter value
    function getParameter(bytes32 key) public view returns (string memory) {
        return parameters[key];
    }
}
