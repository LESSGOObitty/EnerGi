#requires -Version 5.1
param(
    [string]$RpcUrl    = "http://127.0.0.1:8545",
    [string]$StateFile = "C:\bitcoin-erc721\anvil_state.json"
)

$anvil = "C:\Users\Admin\.foundry\bin\anvil.exe"
$cast  = "C:\Users\Admin\.foundry\bin\cast.exe"

if (-not (Get-Process -Name "anvil" -ErrorAction SilentlyContinue)) {
    Write-Host "[BOOT] Starting persistent zero-fee Anvil node (Chain 31337)..." -ForegroundColor Cyan
    Start-Process -FilePath $anvil `
        -ArgumentList "--host 127.0.0.1 --port 8545 --chain-id 31337 --gas-price 0 --base-fee 0 --gas-limit 1000000000 --state $StateFile" `
        -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

& $cast rpc evm_setBlockGasLimit "0x3b9aca00" --rpc-url $RpcUrl | Out-Null
$blk = ((& $cast block-number --rpc-url $RpcUrl) | Out-String).Trim()
Write-Host "[ONLINE] Anvil Chain 31337 Ready | Current Block: #$blk | Gas Price: 0 | Gas Limit: 1B" -ForegroundColor Green