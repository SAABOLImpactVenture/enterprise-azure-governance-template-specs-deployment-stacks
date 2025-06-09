// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GovernanceRegistry
 * @dev Registry for governance parameters and authorized entities in the enterprise solution.
 */
contract GovernanceRegistry {
    // Owner of the registry
    address public owner;
    
    // Mapping of governance parameters
    mapping(bytes32 => string) private parameters;
    
    // Mapping of authorized entities
    mapping(address => bool) public authorizedEntities;
    
    // Events
    event ParameterSet(bytes32 indexed key, string value);
    event EntityAuthorized(address indexed entity, bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Constructor sets the original owner of the registry
     */
    constructor() {
        owner = msg.sender;
        authorizedEntities[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @dev Modifier to restrict function access to the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "GovernanceRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to authorized entities
     */
    modifier onlyAuthorized() {
        require(authorizedEntities[msg.sender], "GovernanceRegistry: caller is not authorized");
        _;
    }
    
    /**
     * @dev Transfers ownership of the registry
     * @param newOwner The address of the new owner
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
     */
    function setEntityAuthorization(address entity, bool status) public onlyOwner {
        authorizedEntities[entity] = status;
        emit EntityAuthorized(entity, status);
    }
    
    /**
     * @dev Sets a governance parameter
     * @param key The parameter key
     * @param value The parameter value
     */
    function setParameter(bytes32 key, string memory value) public onlyAuthorized {
        parameters[key] = value;
        emit ParameterSet(key, value);
    }
    
    /**
     * @dev Gets a governance parameter
     * @param key The parameter key
     * @return The parameter value
     */
    function getParameter(bytes32 key) public view returns (string memory) {
        return parameters[key];
    }
}