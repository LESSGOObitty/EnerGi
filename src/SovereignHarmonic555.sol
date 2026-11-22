// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SovereignHarmonic555 is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_1OF1_CHAINS = 13000;
    uint256 public constant HARMONIC_BATCH  = 555;

    string public baseMetadataUri;
    string public defaultNamespace;
    uint256 public totalMinted;
    bytes32 public harmonicZ2CSeal;

    mapping(uint256 => uint256) public tokenIdOfChain;
    mapping(uint256 => string)  private _customDomainOfChain;
    mapping(bytes32 => uint256) public chainOfDomainHash;

    event HarmonicBatch555Minted(address indexed to, uint256 startChainId, uint256 count, bytes32 indexed z2cSeal);
    event CustomDomainBound(uint256 indexed chainId, uint256 indexed tokenId, string fullDomain);

    constructor(string memory _defaultNamespace, string memory _baseUri, bytes32 _initialZ2CSeal)
        ERC721("Sovereign Harmonic 555 1-of-1 Chains", "HARM555")
        Ownable(msg.sender)
    {
        defaultNamespace = _defaultNamespace;
        baseMetadataUri  = _baseUri;
        harmonicZ2CSeal  = _initialZ2CSeal;
    }

    function computeChainTokenId(uint256 targetChainId) public pure returns (uint256) {
        require(targetChainId >= 1 && targetChainId <= MAX_1OF1_CHAINS, "Out of 1..13000 range");
        return uint256(keccak256(abi.encodePacked("WUSHU_TAICHI_REIKI_QIGONG_555", targetChainId)));
    }

    function mintHarmonicBatch(address to, uint256 startChainId, uint256 count) external onlyOwner {
        require(count >= 1 && count <= HARMONIC_BATCH, "Max 555 per harmonic batch");
        require(startChainId >= 1 && (startChainId + count - 1) <= MAX_1OF1_CHAINS, "Exceeds 13,000 cap");

        for (uint256 i = 0; i < count; ) {
            uint256 cid = startChainId + i;
            uint256 tokenId = computeChainTokenId(cid);
            _mint(to, tokenId);
            tokenIdOfChain[cid] = tokenId;
            unchecked { ++i; }
        }
        totalMinted += count;
        emit HarmonicBatch555Minted(to, startChainId, count, harmonicZ2CSeal);
    }

    function bindCustomDomainToChain(uint256 targetChainId, string calldata fullDomain) external onlyOwner {
        uint256 tokenId = tokenIdOfChain[targetChainId];
        require(tokenId != 0, "Chain ID not minted");
        _customDomainOfChain[targetChainId] = fullDomain;
        chainOfDomainHash[keccak256(bytes(fullDomain))] = targetChainId;
        emit CustomDomainBound(targetChainId, tokenId, fullDomain);
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