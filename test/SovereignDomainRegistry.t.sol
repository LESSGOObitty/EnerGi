// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SovereignDomainRegistry} from "../src/SovereignDomainRegistry.sol";

contract SovereignDomainRegistryTest is Test {
    SovereignDomainRegistry public registry;

    bytes32 constant GENESIS_ROOT = 0x10342972aef326bdea0673a46f478a4a38cdb868115a070449de00a67ea1acd2;
    address public alice = makeAddr("alice");
    address public unauthorized = makeAddr("unauthorized");

    function setUp() public {
        registry = new SovereignDomainRegistry(GENESIS_ROOT);
    }

    function testInitialMerkleRootAndExtensions() public view {
        assertEq(registry.getMerkleRoot(), GENESIS_ROOT);
        assertEq(registry.infrastructureMerkleRoot(), GENESIS_ROOT);
        assertEq(registry.name(), "SovereignDomainRegistry");
        assertEq(registry.symbol(), "SDR");
        assertEq(registry.registeredExtensions(0), "com");
        assertEq(registry.registeredExtensions(6), "xyo");
    }

    function testMintAndTokenURI() public {
        string memory uri = "ipfs://sha256-10342972/robdoe.com.json";
        registry.mintSovereignAsset(alice, 1, uri);
        assertEq(registry.ownerOf(1), alice);
        assertEq(registry.tokenURI(1), uri);
        assertEq(registry.totalMinted(), 1);
    }

    function testUpdateMerkleRootAsOwner() public {
        bytes32 nextRoot = keccak256("NEXT_MERKLE_DAG_ROOT");
        registry.updateMerkleRoot(nextRoot);
        assertEq(registry.getMerkleRoot(), nextRoot);
    }

    function testFuzzMintArbitraryIds(uint256 tokenId, uint8 tldSeed) public {
        vm.assume(tokenId > 0 && tokenId < type(uint128).max);
        string[5] memory tlds = ["robdoe.com", "robdoe.io", "robdoe.zil", "robdoe.pw", "robdoe.xyo"];
        string memory uri = tlds[tldSeed % 5];

        registry.mintSovereignAsset(alice, tokenId, uri);
        assertEq(registry.ownerOf(tokenId), alice);
        assertEq(registry.tokenURI(tokenId), uri);
    }

    function testRevertWhenUnauthorizedCallsAdmin() public {
        vm.startPrank(unauthorized);
        vm.expectRevert();
        registry.mintSovereignAsset(unauthorized, 99, "ipfs://fail.com");
        vm.expectRevert();
        registry.updateMerkleRoot(bytes32(uint256(1)));
        vm.stopPrank();
    }
}