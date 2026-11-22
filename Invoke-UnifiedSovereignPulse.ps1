#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RpcUrl     = "http://127.0.0.1:8545",
    [string]$PrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    [string]$cReal      = "-500000000000000000",
    [string]$cImag      = "250000000000000000",
    [int]$MaxIter       = 64,
    [int]$YangForce     = 108,
    [int]$YinYield      = 108,
    [string]$SerialPort = "COM5",
    [int]$BaudRate      = 115200,
    [switch]$EnableAcoustic
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cast    = "C:\Users\Admin\.foundry\bin\cast.exe"
$eqAddr  = "0x172076E0166D1F9Cc711C77Adf8488051744980C"
$arcAddr = "0xCD8a1C3ba11CF5ECfa6267617243239504a98d90"

$masterRoot = ((& $cast call $arcAddr "globalMasterRoot()(bytes32)" --rpc-url $RpcUrl) | Out-String).Trim()

# 1. Compute & seal bounded z = z^2 + c equilibrium pulse on-chain
& $cast send $eqAddr "sealHarmonicPulse(int256,int256,uint256,uint256,uint256,bytes32)" --private-key $PrivateKey --rpc-url $RpcUrl -- $cReal $cImag $MaxIter $YangForce $YinYield $masterRoot | Out-Null

$seal   = ((& $cast call $eqAddr "currentEquilibriumSeal()(bytes32)" --rpc-url $RpcUrl) | Out-String).Trim()
$pulses = ((& $cast call $eqAddr "pulseCount()(uint256)" --rpc-url $RpcUrl) | Out-String).Trim()

# 2. Propagate verified equilibrium seal across ERC-20, ERC-721, and ERC-1155
foreach ($addr in @(
    "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e",
    "0x0165878A594ca255338adfa4d48449f69242Eb8F",
    "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"
)) {
    & $cast send $addr "updateMerkleRoot(bytes32)" $seal --private-key $PrivateKey --rpc-url $RpcUrl | Out-Null
}

Write-Host "[ON-CHAIN] Pulse #$pulses Sealed & Synced | Seal: $seal" -ForegroundColor Green

# 3. Optional Serial UART Dispatch (COM5) if hardware port is attached
if ([System.IO.Ports.SerialPort]::GetPortNames() -contains $SerialPort) {
    $sp = New-Object System.IO.Ports.SerialPort $SerialPort, $BaudRate, ([System.IO.Ports.Parity]::None), 8, ([System.IO.Ports.StopBits]::One)
    try {
        $sp.Open()
        $frame = "SOVEREIGN_PULSE|PORT=$SerialPort|PULSE=$pulses|SEAL=$seal`r`n"
        $sp.Write($frame)
        Write-Host "[SERIAL TX -> $SerialPort @ $BaudRate] Dispatched telemetry frame." -ForegroundColor Cyan
    }
    finally {
        if ($sp.IsOpen) { $sp.Close() }
        $sp.Dispose()
    }
} else {
    Write-Host "[SERIAL] $SerialPort not currently attached; skipping UART dispatch." -ForegroundColor DarkGray
}

# 4. Optional 256-Bit Bell 202 Acoustic FSK Broadcast
if ($EnableAcoustic -and (Test-Path "C:\bitcoin-erc721\Invoke-AcousticSealBroadcast.ps1")) {
    & "C:\bitcoin-erc721\Invoke-AcousticSealBroadcast.ps1" -Rpc $RpcUrl -EqContract $eqAddr
}