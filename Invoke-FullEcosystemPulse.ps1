#requires -Version 5.1
param(
    [string]$cReal = "-500000000000000000",  # -0.50 * 1e18
    [string]$cImag = "250000000000000000",   # +0.25 * 1e18
    [int]$MaxIter  = 64,
    [int]$Yang     = 108,
    [int]$Yin      = 108,
    [string]$Rpc   = "http://127.0.0.1:8545"
)

$cast    = "C:\Users\Admin\.foundry\bin\cast.exe"
$privKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
$eqAddr  = "0x172076E0166D1F9Cc711C77Adf8488051744980C"
$arcAddr = "0xCD8a1C3ba11CF5ECfa6267617243239504a98d90"

$masterRoot = ((& $cast call $arcAddr "globalMasterRoot()(bytes32)" --rpc-url $Rpc) | Out-String).Trim()

# 1. Compute & seal bounded z = z^2 + c equilibrium pulse on-chain
& $cast send $eqAddr "sealHarmonicPulse(int256,int256,uint256,uint256,uint256,bytes32)" --private-key $privKey --rpc-url $Rpc -- $cReal $cImag $MaxIter $Yang $Yin $masterRoot | Out-Null

$newSeal = ((& $cast call $eqAddr "currentEquilibriumSeal()(bytes32)" --rpc-url $Rpc) | Out-String).Trim()
$pCount  = ((& $cast call $eqAddr "pulseCount()(uint256)" --rpc-url $Rpc) | Out-String).Trim()

# 2. Propagate verified equilibrium seal across ERC-20, ERC-721, and ERC-1155
foreach ($c in @(
    "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e",
    "0x0165878A594ca255338adfa4d48449f69242Eb8F",
    "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"
)) {
    & $cast send $c "updateMerkleRoot(bytes32)" $newSeal --private-key $privKey --rpc-url $Rpc | Out-Null
}

Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "  FULL ECOSYSTEM HARMONIC PULSE #$pCount SEALED & SYNCED (z = z^2 + c)" -ForegroundColor Green
Write-Host "  Equilibrium Seal : $newSeal" -ForegroundColor Cyan
Write-Host "  Synced Contracts : ERC-20 | ERC-721 | ERC-1155 | EquilibriumEngine" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor DarkCyan
if (Test-Path 'C:\bitcoin-erc721\Invoke-AcousticSealBroadcast.ps1') { & 'C:\bitcoin-erc721\Invoke-AcousticSealBroadcast.ps1' }
