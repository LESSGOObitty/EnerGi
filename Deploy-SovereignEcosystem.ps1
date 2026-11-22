#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RpcUrl     = "http://127.0.0.1:8545",
    [string]$PrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    [string]$Treasury   = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
    [string]$MasterRoot = "0x1d98b5ba5dbf2d70afc2036f665d42b76af66771b20db27928c258b0eb9a344a"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$forge   = "C:\Users\Admin\.foundry\bin\forge.exe"
$cast    = "C:\Users\Admin\.foundry\bin\cast.exe"
$chainId = ((& $cast chain-id --rpc-url $RpcUrl) | Out-String).Trim()
$deployer = ((& $cast wallet address --private-key $PrivateKey) | Out-String).Trim()

function Deploy-Contract {
    param([string]$Target, [string[]]$ConstructorArgs = @())
    $cmdArgs = @("create", $Target, "--rpc-url", $RpcUrl, "--private-key", $PrivateKey, "--broadcast")
    if ($ConstructorArgs.Count -gt 0) {
        $cmdArgs += "--constructor-args"
        $cmdArgs += $ConstructorArgs
    }
    $out = (& $forge @cmdArgs 2>&1) | Out-String
    $m   = [regex]::Match($out, 'Deployed to:\s*(0x[0-9a-fA-F]{40})')
    if (-not $m.Success) { throw "Failed deploying $Target :`n$out" }
    return $m.Groups[1].Value
}

Write-Host "[DEPLOY] Target Chain ID: $chainId | Deployer: $deployer" -ForegroundColor Cyan

$c20   = Deploy-Contract -Target "src/SovereignToken20.sol:SovereignToken20" -ConstructorArgs @($MasterRoot)
$c721  = Deploy-Contract -Target "src/SovereignDomainRegistryV2.sol:SovereignDomainRegistryV2" -ConstructorArgs @($MasterRoot, $deployer, "500")
$cRdn  = Deploy-Contract -Target "src/RobDoeNFT.sol:RobDoeNFT" -ConstructorArgs @($Treasury)
$c1155 = Deploy-Contract -Target "src/SovereignLattice1155.sol:SovereignLattice1155" -ConstructorArgs @("ipfs://sovereign-lattice/{id}.json", $MasterRoot)
$cArc  = Deploy-Contract -Target "src/SovereignFullArchive.sol:SovereignFullArchive"
$cEq   = Deploy-Contract -Target "src/SovereignEquilibriumEngine.sol:SovereignEquilibriumEngine"

$manifest = [ordered]@{
    chain_id      = [int]$chainId
    rpc_url       = $RpcUrl
    deployer      = $deployer
    treasury      = $Treasury
    master_root   = $MasterRoot
    deployed_utc  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    contracts     = [ordered]@{
        SovereignToken20           = $c20
        SovereignDomainRegistryV2  = $c721
        RobDoeNFT                  = $cRdn
        SovereignLattice1155       = $c1155
        SovereignFullArchive       = $cArc
        SovereignEquilibriumEngine = $cEq
    }
}

$outFile = "C:\bitcoin-erc721\deployment_chain_$chainId.json"
[System.IO.File]::WriteAllText($outFile, ($manifest | ConvertTo-Json -Depth 4), [System.Text.UTF8Encoding]::new($false))

Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "  DEPLOYMENT COMPLETE (CHAIN $chainId) -> $outFile" -ForegroundColor Green
$manifest.contracts.GetEnumerator() | ForEach-Object {
    Write-Host ("  {0,-28} : {1}" -f $_.Key, $_.Value) -ForegroundColor Yellow
}
Write-Host "==============================================================================" -ForegroundColor DarkCyan