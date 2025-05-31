// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyContract {
    uint256 private value;
    address private owner;

    event ValueSet(uint256 newValue, address indexed setter);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor(uint256 initialValue) {
        value = initialValue;
        owner = msg.sender;
    }

    function setValue(uint256 newValue) public onlyOwner {
        value = newValue;
        emit ValueSet(newValue, msg.sender);
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}
