// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SovereignDomainRegistryV2} from "../src/SovereignDomainRegistryV2.sol";
import {RobDoeNFT} from "../src/RobDoeNFT.sol";
import {SovereignFullArchive} from "../src/SovereignFullArchive.sol";

contract FullStackSuiteTest is Test {
    SovereignDomainRegistryV2 public v2;
    RobDoeNFT public rdn;
    SovereignFullArchive public archive;

    bytes32 constant MASTER = 0x1d98b5ba5dbf2d70afc2036f665d42b76af66771b20db27928c258b0eb9a344a;
    address public alice = makeAddr("alice");
    address public treasury = makeAddr("treasury");

    function setUp() public {
        v2 = new SovereignDomainRegistryV2(MASTER, treasury, 500);
        rdn = new RobDoeNFT(treasury);
        archive = new SovereignFullArchive();
    }

    function testBatchMintAndReverseResolution() public {
        uint256[] memory ids = new uint256[](2);
        string[] memory names = new string[](2);
        string[] memory uris = new string[](2);

        ids[0] = uint256(keccak256("robdoe.com"));
        ids[1] = uint256(keccak256("erc721.com"));
        names[0] = "robdoe.com";
        names[1] = "erc721.com";
        uris[0] = "ipfs://robdoe.com";
        uris[1] = "ipfs://erc721.com";

        v2.batchMintDomains(alice, ids, names, uris);

        string[] memory resolved = v2.domainsOf(alice);
        assertEq(resolved.length, 2);
        assertEq(resolved[0], "robdoe.com");
        assertEq(resolved[1], "erc721.com");

        (address receiver, uint256 royaltyAmt) = v2.royaltyInfo(ids[0], 10 ether);
        assertEq(receiver, treasury);
        assertEq(royaltyAmt, 0.5 ether);
    }

    function testRobDoeNftMintAndTreasurySplit() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        rdn.mint{value: 0.08 ether}();

        assertEq(rdn.ownerOf(1), alice);
        assertEq(treasury.balance, 0.076 ether);
    }

    function testArchiveSealing() public {
        archive.sealArchive("erc721.com", MASTER, 1, "ipfs://erc721.com");
        archive.sealGlobalMaster(MASTER);

        assertEq(archive.totalArchives(), 1);
        assertEq(archive.globalMasterRoot(), MASTER);
    }
}