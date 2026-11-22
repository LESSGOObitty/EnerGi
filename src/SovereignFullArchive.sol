// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SovereignFullArchive is Ownable {
    struct ArchiveRecord {
        string label;
        bytes32 merkleRoot;
        uint256 fileCount;
        string manifestUri;
        uint256 timestamp;
    }

    bytes32 public globalMasterRoot;
    string[] public archiveLabels;
    mapping(string => ArchiveRecord) private _records;

    event ArchiveSealed(string indexed label, bytes32 indexed merkleRoot, uint256 fileCount, string manifestUri);
    event GlobalMasterSealed(bytes32 indexed masterRoot, uint256 archiveCount, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    function sealArchive(
        string calldata label,
        bytes32 merkleRoot,
        uint256 fileCount,
        string calldata manifestUri
    ) external onlyOwner {
        if (_records[label].timestamp == 0) {
            archiveLabels.push(label);
        }
        _records[label] = ArchiveRecord({
            label: label,
            merkleRoot: merkleRoot,
            fileCount: fileCount,
            manifestUri: manifestUri,
            timestamp: block.timestamp
        });
        emit ArchiveSealed(label, merkleRoot, fileCount, manifestUri);
    }

    function sealGlobalMaster(bytes32 _masterRoot) external onlyOwner {
        globalMasterRoot = _masterRoot;
        emit GlobalMasterSealed(_masterRoot, archiveLabels.length, block.timestamp);
    }

    function getArchive(string calldata label) external view returns (ArchiveRecord memory) {
        return _records[label];
    }

    function totalArchives() external view returns (uint256) {
        return archiveLabels.length;
    }
}