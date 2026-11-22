# Sovereign Multi-Token & Cryptographic Equilibrium Ecosystem

An integrated Foundry/Solidity smart contract architecture paired with PowerShell 5.1 orchestration, cross-platform Node.js telemetry, and dual-channel (`COM5` UART + 256-bit Bell 202 Acoustic FSK) air-gap verification.

## Smart Contract Architecture

| Contract | Standard / Role | Key Capabilities |
| :--- | :--- | :--- |
| `SovereignToken20.sol` | ERC-20 Utility (`SOV`) | `1,000,000 SOV` supply anchored to `infrastructureMerkleRoot` |
| `SovereignDomainRegistry.sol` | ERC-721 Domain Registry V1 | Deterministic EIP-137 `namehash` minting & URI resolution |
| `SovereignDomainRegistryV2.sol` | ERC-721 + ERC-2981 V2 | On-chain reverse resolution (`domainsOf`), batch minting, `5%` royalties |
| `RobDoeNFT.sol` | ERC-721Enumerable (`RDN`) | `0.08 ETH` mint with automated `0.076 ETH` treasury routing |
| `SovereignLattice1155.sol` | ERC-1155 Multi-Token | Batch asset minting (`mintBatchAssets`) synced to global root |
| `SovereignFullArchive.sol` | On-Chain Merkle Registry | Immutable multi-repository `bytes32` root & file-count ledger |
| `SovereignEquilibriumEngine.sol` | Fixed-Point Math Verifier | On-chain $z = z^2 + c$ Mandelbrot boundedness ($|z|^2 \le 4.0$) & dual-polarity gate |

## Quick Start

### 1. Run Foundry Test Suite
```bash
forge test -vv
```

### 2. Deploy to Any EVM Network (Local Anvil or Public Testnet)
```powershell
.\Deploy-SovereignEcosystem.ps1 -RpcUrl "http://127.0.0.1:8545" -PrivateKey "<YOUR_PRIVATE_KEY>"
```

### 3. Execute a Unified Harmonic Pulse (On-Chain + COM5 + Acoustic FSK)
```powershell
.\Invoke-UnifiedSovereignPulse.ps1 -SerialPort "COM5" -EnableAcoustic
```

### 4. Air-Gap Acoustic Verification
Open `acoustic_cockpit.html` in a Chromium/Edge browser, enable the Web Audio microphone decoder (`1200 Hz / 2200 Hz` Goertzel DSP), and broadcast a pulse via `Invoke-AcousticSealBroadcast.ps1`.