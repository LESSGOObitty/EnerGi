// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SovereignToken20} from "../src/SovereignToken20.sol";
import {SovereignDomainRegistry} from "../src/SovereignDomainRegistry.sol";
import {SovereignLattice1155} from "../src/SovereignLattice1155.sol";

contract TriTokenStackTest is Test {
    SovereignToken20 public token20;
    SovereignDomainRegistry public registry721;
    SovereignLattice1155 public lattice1155;

    bytes32 constant ROOT_A = 0x10342972aef326bdea0673a46f478a4a38cdb868115a070449de00a67ea1acd2;
    bytes32 constant ROOT_B = 0x947fe91018e6f3c650abac1a39251c8e3c21afb17dcd3999dc927ae18a63d2ba;
    address public alice = makeAddr("alice");

    function setUp() public {
        token20 = new SovereignToken20(ROOT_A, 1_000_000 ether);
        registry721 = new SovereignDomainRegistry(ROOT_A);
        lattice1155 = new SovereignLattice1155(ROOT_A, "ipfs://tri-stack/{id}.json");
    }

    function testTriTokenBalancesAndBatchMint() public {
        assertEq(token20.balanceOf(address(this)), 1_000_000 ether);

        registry721.mintSovereignAsset(alice, 1, "ipfs://robdoe.com");
        assertEq(registry721.ownerOf(1), alice);
        assertEq(registry721.tokenURI(1), "ipfs://robdoe.com");

        uint256[] memory ids = new uint256[](3);
        uint256[] memory amts = new uint256[](3);
        ids[0] = 1; ids[1] = 2; ids[2] = 3;
        amts[0] = 100; amts[1] = 200; amts[2] = 300;

        lattice1155.mintBatchAssets(alice, ids, amts);
        assertEq(lattice1155.balanceOf(alice, 1), 100);
        assertEq(lattice1155.balanceOf(alice, 3), 300);
    }

    function testSynchronizedRootUpdateAcrossAllThree() public {
        token20.updateMerkleRoot(ROOT_B);
        registry721.updateMerkleRoot(ROOT_B);
        lattice1155.updateMerkleRoot(ROOT_B);

        assertEq(token20.infrastructureMerkleRoot(), ROOT_B);
        assertEq(registry721.getMerkleRoot(), ROOT_B);
        assertEq(lattice1155.infrastructureMerkleRoot(), ROOT_B);
    }
}