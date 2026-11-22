// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SovereignSubdomain13K is ERC721, Ownable {
    using Strings for uint256;

    // EIP-137 namehash("erc721.com")
    bytes32 public constant PARENT_NODE = 0x111c2c33dea69e68a7d59584571497eecd885a4e142a87296d6481e109fc97cc;
    uint256 public constant MAX_1OF1_SUPPLY = 13000;

    string public baseMetadataUri;
    uint256 public totalMinted;
    mapping(uint256 => uint256) public indexOfTokenId;

    event SubdomainRangeMinted(address indexed to, uint256 startIndex, uint256 endIndex);

    constructor(string memory _baseUri)
        ERC721("ERC721.com 13K 1-of-1 Subdomains", "ERC721K")
        Ownable(msg.sender)
    {
        baseMetadataUri = _baseUri;
    }

    function computeSubdomainId(uint256 index) public pure returns (uint256) {
        require(index >= 1 && index <= MAX_1OF1_SUPPLY, "Out of 1..13000 range");
        bytes32 labelHash = keccak256(bytes(index.toString()));
        return uint256(keccak256(abi.encodePacked(PARENT_NODE, labelHash)));
    }

    function mintRange(address to, uint256 startIndex, uint256 count) external onlyOwner {
        require(startIndex >= 1 && (startIndex + count - 1) <= MAX_1OF1_SUPPLY, "Exceeds 13,000 cap");
        for (uint256 i = 0; i < count; i++) {
            uint256 idx = startIndex + i;
            uint256 tokenId = computeSubdomainId(idx);
            _mint(to, tokenId);
            indexOfTokenId[tokenId] = idx;
            totalMinted++;
        }
        emit SubdomainRangeMinted(to, startIndex, startIndex + count - 1);
    }

    function subdomainName(uint256 index) external pure returns (string memory) {
        require(index >= 1 && index <= MAX_1OF1_SUPPLY, "Out of 1..13000 range");
        return string(abi.encodePacked(index.toString(), ".erc721.com"));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 idx = indexOfTokenId[tokenId];
        return string(abi.encodePacked(baseMetadataUri, idx.toString(), ".erc721.com.json"));
    }
}