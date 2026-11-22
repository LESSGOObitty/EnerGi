// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SovereignOmniChain13K is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_1OF1_CHAINS = 13000;
    string public baseMetadataUri;
    string public defaultNamespace; // e.g., "erc721.com", "robdoe.zil", "robdoe.her", "robdoe.info"
    uint256 public totalMinted;

    string[] public supportedTlds;
    mapping(string => bool) public isSupportedTld;

    // Bijective 1-of-1 mapping: Chain ID (1..13000) <-> Token ID <-> Custom Domain/Subdomain
    mapping(uint256 => uint256) public chainIdOfToken;
    mapping(uint256 => uint256) public tokenIdOfChain;
    mapping(uint256 => string)  private _customDomainOfChain;
    mapping(bytes32 => uint256) public chainOfDomainHash;

    event OmniChainBatchMinted(address indexed to, uint256 startChainId, uint256 endChainId);
    event CustomDomainBound(uint256 indexed chainId, uint256 indexed tokenId, string fullDomain);

    constructor(string memory _defaultNamespace, string memory _baseUri)
        ERC721("Sovereign Omni-TLD 13K 1-of-1 Chains", "OMNI13K")
        Ownable(msg.sender)
    {
        defaultNamespace = _defaultNamespace;
        baseMetadataUri = _baseUri;

        string[8] memory initialTlds = ["com", "info", "zil", "her", "pw", "xyo", "io", "inc"];
        for (uint256 i = 0; i < initialTlds.length; i++) {
            supportedTlds.push(initialTlds[i]);
            isSupportedTld[initialTlds[i]] = true;
        }
    }

    function addTld(string calldata tld) external onlyOwner {
        require(!isSupportedTld[tld], "TLD already registered");
        supportedTlds.push(tld);
        isSupportedTld[tld] = true;
    }

    function computeChainTokenId(uint256 targetChainId) public pure returns (uint256) {
        require(targetChainId >= 1 && targetChainId <= MAX_1OF1_CHAINS, "Out of 1..13000 range");
        return uint256(keccak256(abi.encodePacked("SOVEREIGN_1OF1_CHAIN_DEED", targetChainId)));
    }

    function mintChainRange(address to, uint256 startChainId, uint256 count) external onlyOwner {
        require(startChainId >= 1 && (startChainId + count - 1) <= MAX_1OF1_CHAINS, "Exceeds 13,000 cap");
        for (uint256 i = 0; i < count; i++) {
            uint256 cid = startChainId + i;
            uint256 tokenId = computeChainTokenId(cid);
            _mint(to, tokenId);
            chainIdOfToken[tokenId] = cid;
            tokenIdOfChain[cid] = tokenId;
            totalMinted++;
        }
        emit OmniChainBatchMinted(to, startChainId, startChainId + count - 1);
    }

    /// @notice Bind any root domain or subdomain (.com, .info, .zil, .her, etc.) to a specific 1-of-1 Chain ID
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
        if (bytes(custom).length > 0) {
            return custom;
        }
        return string(abi.encodePacked(targetChainId.toString(), ".", defaultNamespace));
    }

    function resolveChainForDomain(string calldata fullDomain) external view returns (uint256) {
        return chainOfDomainHash[keccak256(bytes(fullDomain))];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 cid = chainIdOfToken[tokenId];
        return string(abi.encodePacked(baseMetadataUri, resolveDomainForChain(cid), ".json"));
    }
}