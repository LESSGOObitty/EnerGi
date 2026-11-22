// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RobDoeNFT is ERC721Enumerable, Ownable {
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant TREASURY_SHARE = 0.076 ether;
    uint256 public tokenCounter;
    address public immutable treasury;

    constructor(address _treasury) ERC721("RobDoe Collectible", "RDN") Ownable(msg.sender) {
        treasury = _treasury != address(0) ? _treasury : msg.sender;
    }

    function mint() public payable {
        require(msg.value >= MINT_PRICE, "Insufficient ETH sent");
        
        uint256 newTokenId = ++tokenCounter;
        _safeMint(msg.sender, newTokenId);

        // Route structural proceeds exactly as defined in the flow frame
        (bool success, ) = payable(treasury).call{value: TREASURY_SHARE}("");
        require(success, "Treasury payout failed");
    }
}