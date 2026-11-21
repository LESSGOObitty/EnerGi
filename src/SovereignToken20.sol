// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SovereignToken20 is ERC20, Ownable {
    bytes32 public infrastructureMerkleRoot;

    constructor(bytes32 _merkleRoot, uint256 initialSupply)
        ERC20("SovereignUtility", "SOV")
        Ownable(msg.sender)
    {
        infrastructureMerkleRoot = _merkleRoot;
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        infrastructureMerkleRoot = _newRoot;
    }
}