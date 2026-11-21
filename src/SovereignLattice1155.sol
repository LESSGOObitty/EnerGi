// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SovereignLattice1155 is ERC1155, Ownable {
    bytes32 public infrastructureMerkleRoot;

    constructor(bytes32 _merkleRoot, string memory baseUri)
        ERC1155(baseUri)
        Ownable(msg.sender)
    {
        infrastructureMerkleRoot = _merkleRoot;
    }

    function mintBatchAssets(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        infrastructureMerkleRoot = _newRoot;
    }
}