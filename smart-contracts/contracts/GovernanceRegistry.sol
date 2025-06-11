// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @prompt Define a registry for on-chain governance parameters & authorized actors
/// @title GovernanceRegistry
/// @dev Registry for governance parameters and authorized entities in the enterprise solution.
contract GovernanceRegistry {
    /// @prompt Track registry owner for privileged operations
    /// @dev Owner of the registry
    address public owner;
    
    /// @prompt Store key → value governance parameters
    /// @dev Mapping of governance parameters
    mapping(bytes32 => string) private parameters;
    
    /// @prompt Track which addresses are allowed to set parameters
    /// @dev Mapping of authorized entities
    mapping(address => bool) public authorizedEntities;
    
    /// @prompt Emit when a parameter is updated on-chain
    /// @dev Events
    event ParameterSet(bytes32 indexed key, string value);
    /// @prompt Emit when an entity’s authorization status changes
    event EntityAuthorized(address indexed entity, bool status);
    /// @prompt Emit when ownership of the registry transfers
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Constructor sets the original owner and auto-authorizes them
     * @prompt Initialize owner and enable them as an authorized entity
     */
    constructor() {
        owner = msg.sender;
        authorizedEntities[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @dev Modifier to restrict access to only the owner
     * @prompt Ensure only the owner can call privileged functions
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "GovernanceRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict access to authorized entities
     * @prompt Ensure only addresses with explicit permission can call
     */
    modifier onlyAuthorized() {
        require(authorizedEntities[msg.sender], "GovernanceRegistry: caller is not authorized");
        _;
    }
    
    /**
     * @dev Transfers ownership of the registry
     * @param newOwner The address of the new owner
     * @prompt Change registry controller; emit event for audit
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "GovernanceRegistry: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Sets the authorization status of an entity
     * @param entity The address of the entity
     * @param status The authorization status
     * @prompt Grant or revoke an address’s ability to set parameters
     */
    function setEntityAuthorization(address entity, bool status) public onlyOwner {
        authorizedEntities[entity] = status;
        emit EntityAuthorized(entity, status);
    }
    
    /**
     * @dev Sets a governance parameter
     * @param key The parameter key
     * @param value The parameter value
     * @prompt Allow authorized entities to update on-chain config parameters
     */
    function setParameter(bytes32 key, string memory value) public onlyAuthorized {
        parameters[key] = value;
        emit ParameterSet(key, value);
    }
    
    /**
     * @dev Gets a governance parameter
     * @param key The parameter key
     * @return The parameter value
     * @prompt Fetch a stored governance parameter by its key
     */
    function getParameter(bytes32 key) public view returns (string memory) {
        return parameters[key];
    }
}
