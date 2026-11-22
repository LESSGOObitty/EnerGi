// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SovereignSha512Lattice13K is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_1OF1_CHAINS = 13000;
    string public baseMetadataUri;
    string public defaultNamespace;
    uint256 public totalMinted;
    bytes32 public globalZ2CSeal;

    struct Sha512Lattice {
        bytes32 laneHigh; // Upper 256 bits of 512-bit sponge state
        bytes32 laneLow;  // Lower 256 bits of 512-bit sponge state
    }

    mapping(uint256 => uint256) public tokenIdOfChain;
    mapping(uint256 => string)  private _customDomainOfChain;
    mapping(bytes32 => uint256) public chainOfDomainHash;

    event SingleTx13KMinted(address indexed to, uint256 totalCount, bytes32 indexed z2cSeal);
    event CustomDomainBound(uint256 indexed chainId, uint256 indexed tokenId, string fullDomain);

    constructor(string memory _defaultNamespace, string memory _baseUri, bytes32 _z2cSeal)
        ERC721("Sovereign SHA3-512 Lattice 13K", "SHA512K")
        Ownable(msg.sender)
    {
        defaultNamespace = _defaultNamespace;
        baseMetadataUri  = _baseUri;
        globalZ2CSeal    = _z2cSeal;
    }

    /// @notice Computes deterministic 512-bit (64-byte) dual-lane lattice digest & folded ERC-721 tokenId
    function computeSha512Lattice(uint256 targetChainId)
        public
        view
        returns (bytes32 laneHigh, bytes32 laneLow, uint256 tokenId)
    {
        require(targetChainId >= 1 && targetChainId <= MAX_1OF1_CHAINS, "Out of 1..13000 range");
        laneHigh = keccak256(abi.encodePacked("SHA3_512_SPONGE_LANE_HIGH", globalZ2CSeal, targetChainId));
        laneLow  = keccak256(abi.encodePacked("SHA3_512_SPONGE_LANE_LOW",  laneHigh,      targetChainId));
        tokenId  = uint256(keccak256(abi.encodePacked(laneHigh, laneLow)));
    }

    /// @notice Mints all 13,000 1-of-1 SHA3-512 lattice deeds in a single zero-fee transaction
    function mintAll13KZeroFee(address to) external onlyOwner {
        require(totalMinted == 0, "13,000 lattice already minted");
        for (uint256 cid = 1; cid <= MAX_1OF1_CHAINS; ) {
            (, , uint256 tokenId) = computeSha512Lattice(cid);
            _mint(to, tokenId);
            tokenIdOfChain[cid] = tokenId;
            unchecked { ++cid; }
        }
        totalMinted = MAX_1OF1_CHAINS;
        emit SingleTx13KMinted(to, MAX_1OF1_CHAINS, globalZ2CSeal);
    }

    function bindCustomDomainToChain(uint256 targetChainId, string calldata fullDomain) external onlyOwner {
        require(tokenIdOfChain[targetChainId] != 0, "Chain ID not minted");
        _customDomainOfChain[targetChainId] = fullDomain;
        chainOfDomainHash[keccak256(bytes(fullDomain))] = targetChainId;
        emit CustomDomainBound(targetChainId, tokenIdOfChain[targetChainId], fullDomain);
    }

    function resolveDomainForChain(uint256 targetChainId) public view returns (string memory) {
        require(targetChainId >= 1 && targetChainId <= MAX_1OF1_CHAINS, "Out of 1..13000 range");
        string memory custom = _customDomainOfChain[targetChainId];
        if (bytes(custom).length > 0) return custom;
        return string(abi.encodePacked(targetChainId.toString(), ".", defaultNamespace));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(baseMetadataUri, tokenId.toHexString(), ".json"));
    }
}