// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SovereignEquilibriumEngine} from "../src/SovereignEquilibriumEngine.sol";

contract EquilibriumEngineTest is Test {
    SovereignEquilibriumEngine public engine;
    bytes32 constant ROOT = 0x1d98b5ba5dbf2d70afc2036f665d42b76af66771b20db27928c258b0eb9a344a;

    function setUp() public {
        engine = new SovereignEquilibriumEngine();
    }

    function testBoundedMandelbrotAndTaiChiWushuSeal() public {
        bytes32 seal = engine.sealHarmonicPulse(-0.5e18, 0.25e18, 32, 108, 108, ROOT);
        assertEq(engine.pulseCount(), 1);
        assertEq(engine.currentEquilibriumSeal(), seal);
    }

    function testRevertOnEscapingDriftTrajectory() public {
        vm.expectRevert("Mandelbrot trajectory escaped: drift detected");
        engine.sealHarmonicPulse(1.5e18, 0, 16, 108, 108, ROOT);
    }
}