// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SovereignDomainRegistryV2 is ERC721URIStorage, ERC2981, Ownable {
    bytes32 public infrastructureMerkleRoot;
    uint256 public totalMinted;
    string[] public supportedExtensions;

    mapping(uint256 => string) public domainNameOf;
    mapping(address => uint256[]) private _ownedTokenIds;

    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event DomainDeedMinted(address indexed to, uint256 indexed tokenId, string domainName, string uri);

    constructor(bytes32 _initialMerkleRoot, address _royaltyReceiver, uint96 _royaltyFeeBps)
        ERC721("Sovereign Domain Deed V2", "SDD2")
        Ownable(msg.sender)
    {
        infrastructureMerkleRoot = _initialMerkleRoot;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeBps);
        supportedExtensions = ["com", "io", "zil", "info", "pw", "her", "xyo", "inc"];
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        emit MerkleRootUpdated(infrastructureMerkleRoot, _newRoot);
        infrastructureMerkleRoot = _newRoot;
    }

    function mintDomainDeed(
        address to,
        uint256 tokenId,
        string calldata domainName,
        string calldata uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        domainNameOf[tokenId] = domainName;
        _ownedTokenIds[to].push(tokenId);
        totalMinted++;
        emit DomainDeedMinted(to, tokenId, domainName, uri);
    }

    function batchMintDomains(
        address to,
        uint256[] calldata tokenIds,
        string[] calldata domainNames,
        string[] calldata uris
    ) external onlyOwner {
        require(tokenIds.length == domainNames.length && domainNames.length == uris.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintDomainDeed(to, tokenIds[i], domainNames[i], uris[i]);
        }
    }

    function domainsOf(address owner) external view returns (string[] memory) {
        uint256[] storage ids = _ownedTokenIds[owner];
        string[] memory names = new string[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            if (_ownerOf(ids[i]) == owner) {
                names[i] = domainNameOf[ids[i]];
            }
        }
        return names;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return infrastructureMerkleRoot;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}