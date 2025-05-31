// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyContract {
    string private value;

    constructor(string memory _value) {
        value = _value;
    }

    function getValue() public view returns (string memory) {
        return value;
    }

    function setValue(string memory _value) public {
        value = _value;
    }
}
