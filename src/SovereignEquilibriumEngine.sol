// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SovereignEquilibriumEngine is Ownable {
    int256 public constant SCALE = 1e18;
    int256 public constant ESCAPE_RADIUS_SQ = 4e18;

    struct PulseEquilibrium {
        int256 zReal;
        int256 zImag;
        uint256 iterations;
        uint256 wushuYangForce;
        uint256 taiChiYinYield;
        bytes32 latticeSeal;
        bool bounded;
    }

    uint256 public pulseCount;
    bytes32 public currentEquilibriumSeal;
    mapping(uint256 => PulseEquilibrium) public pulses;

    event EquilibriumResolved(
        uint256 indexed pulseId,
        int256 zReal,
        int256 zImag,
        uint256 iterations,
        bytes32 indexed latticeSeal
    );

    constructor() Ownable(msg.sender) {}

    function computeMandelbrot(
        int256 cReal,
        int256 cImag,
        uint256 maxIter
    ) public pure returns (int256 zReal, int256 zImag, uint256 iter, bool bounded) {
        zReal = 0;
        zImag = 0;
        bounded = true;

        for (uint256 i = 0; i < maxIter; i++) {
            int256 zr2 = (zReal * zReal) / SCALE;
            int256 zi2 = (zImag * zImag) / SCALE;

            if (zr2 + zi2 > ESCAPE_RADIUS_SQ) {
                return (zReal, zImag, i, false);
            }

            int256 nextImag = ((2 * zReal * zImag) / SCALE) + cImag;
            int256 nextReal = (zr2 - zi2) + cReal;

            zReal = nextReal;
            zImag = nextImag;
            iter = i + 1;
        }
    }

    function sealHarmonicPulse(
        int256 cReal,
        int256 cImag,
        uint256 maxIter,
        uint256 wushuYangForce,
        uint256 taiChiYinYield,
        bytes32 externalRoot
    ) external onlyOwner returns (bytes32 seal) {
        require(wushuYangForce > 0 && taiChiYinYield > 0, "Zero polarity");
        (int256 zr, int256 zi, uint256 iters, bool bounded) = computeMandelbrot(cReal, cImag, maxIter);
        require(bounded, "Mandelbrot trajectory escaped: drift detected");

        pulseCount++;
        seal = keccak256(
            abi.encodePacked(pulseCount, zr, zi, iters, wushuYangForce, taiChiYinYield, externalRoot)
        );

        pulses[pulseCount] = PulseEquilibrium({
            zReal: zr,
            zImag: zi,
            iterations: iters,
            wushuYangForce: wushuYangForce,
            taiChiYinYield: taiChiYinYield,
            latticeSeal: seal,
            bounded: bounded
        });

        currentEquilibriumSeal = seal;
        emit EquilibriumResolved(pulseCount, zr, zi, iters, seal);
    }
}