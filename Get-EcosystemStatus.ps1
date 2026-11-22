#requires -Version 5.1
param([string]$RpcUrl = "http://127.0.0.1:8545")

$cast  = "C:\Users\Admin\.foundry\bin\cast.exe"
$owner = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

$blk     = ((& $cast block-number --rpc-url $RpcUrl) | Out-String).Trim()
$sovRaw  = ((& $cast call 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e "balanceOf(address)(uint256)" $owner --rpc-url $RpcUrl) | Out-String).Trim()
$domCnt  = ((& $cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "balanceOf(address)(uint256)" $owner --rpc-url $RpcUrl) | Out-String).Trim()
$rdnCnt  = ((& $cast call 0xdbC43Ba45381e02825b14322cDdd15eC4B3164E6 "totalSupply()(uint256)" --rpc-url $RpcUrl) | Out-String).Trim()
$arcCnt  = ((& $cast call 0xCD8a1C3ba11CF5ECfa6267617243239504a98d90 "totalArchives()(uint256)" --rpc-url $RpcUrl) | Out-String).Trim()
$pulses  = ((& $cast call 0x172076E0166D1F9Cc711C77Adf8488051744980C "pulseCount()(uint256)" --rpc-url $RpcUrl) | Out-String).Trim()
$eqSeal  = ((& $cast call 0x172076E0166D1F9Cc711C77Adf8488051744980C "currentEquilibriumSeal()(bytes32)" --rpc-url $RpcUrl) | Out-String).Trim()
$sha13k  = ((& $cast call 0x82EdA215Fa92B45a3a76837C65Ab862b6C7564a8 "totalMinted()(uint256)" --rpc-url $RpcUrl) | Out-String).Trim()

Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "  SOVEREIGN ECOSYSTEM LIVE TELEMETRY & AUDIT (CHAIN 31337 | BLOCK #$blk)" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "  ERC-20 Utility (SOV)      : $sovRaw wei (0xB7f8...4F5e)" -ForegroundColor Cyan
Write-Host "  ERC-721 Domain Deeds      : $domCnt minted (0x0165...Eb8F)" -ForegroundColor Cyan
Write-Host "  ERC-721 Collectibles (RDN): $rdnCnt minted (0xdbC4...64E6)" -ForegroundColor Cyan
Write-Host "  SHA3-512 13K Chains       : $sha13k / 13,000 minted (0x82Ed...64a8)" -ForegroundColor Yellow
Write-Host "  Full Infrastructure Ledger: $arcCnt sealed archives (0xCD8a...3042)" -ForegroundColor Cyan
Write-Host "  Equilibrium Engine (z²+c) : $pulses pulses | Seal: $eqSeal" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor DarkCyan