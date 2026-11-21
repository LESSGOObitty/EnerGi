// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SovereignDomainRegistry
 * @dev ERC-721 Registry binding multi-extension domains (.com, .io, .zil, .info, .pw, .her, .xyo)
 *      and updatable Merkle DAG infrastructure roots to sequential tokens.
 */
contract SovereignDomainRegistry is ERC721, Ownable {

    bytes32 public infrastructureMerkleRoot;
    uint256 public totalMinted;
    string[] public registeredExtensions = ["com", "io", "zil", "info", "pw", "her", "xyo"];

    mapping(uint256 => string) private _tokenDomainURIs;

    event MerkleRootUpdated(bytes32 indexed previousRoot, bytes32 indexed newRoot, uint256 timestamp);

    constructor(bytes32 _merkleRoot) ERC721("SovereignDomainRegistry", "SDR") Ownable(msg.sender) {
        infrastructureMerkleRoot = _merkleRoot;
        emit MerkleRootUpdated(bytes32(0), _merkleRoot, block.timestamp);
    }

    function mintSovereignAsset(address recipient, uint256 tokenId, string memory domainUri) external onlyOwner {
        _safeMint(recipient, tokenId);
        _tokenDomainURIs[tokenId] = domainUri;
        if (tokenId > totalMinted) {
            totalMinted = tokenId;
        }
    }

    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        bytes32 oldRoot = infrastructureMerkleRoot;
        infrastructureMerkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(oldRoot, _newMerkleRoot, block.timestamp);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return infrastructureMerkleRoot;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenDomainURIs[tokenId];
    }
}