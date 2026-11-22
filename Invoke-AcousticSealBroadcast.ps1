#requires -Version 5.1
param(
    [string]$Rpc        = "http://127.0.0.1:8545",
    [string]$EqContract = "0x172076E0166D1F9Cc711C77Adf8488051744980C",
    [int]$SampleRate    = 44100,
    [int]$BitMs         = 20,
    [double]$Amplitude  = 0.70,
    [string]$WavOut     = "C:\bitcoin-erc721\latest_equilibrium_pulse.wav",
    [switch]$NoPlay
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cast = "C:\Users\Admin\.foundry\bin\cast.exe"
if (-not (Test-Path -LiteralPath $cast)) {
    $cast = "cast"
}

$sealRaw   = ((& $cast call $EqContract "currentEquilibriumSeal()(bytes32)" --rpc-url $Rpc) | Out-String).Trim()
$pulsesRaw = ((& $cast call $EqContract "pulseCount()(uint256)" --rpc-url $Rpc) | Out-String).Trim()
$sealHex   = (($sealRaw -split '\s+')[0] -replace '^0x', '').ToLowerInvariant().PadLeft(64, '0')
$pulses    = ($pulsesRaw -split '\s+')[0]

$bitStr = New-Object System.Text.StringBuilder 256
foreach ($ch in $sealHex.ToCharArray()) {
    $val = [Convert]::ToInt32([string]$ch, 16)
    [void]$bitStr.Append([Convert]::ToString($val, 2).PadLeft(4, '0'))
}

$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)

function Add-Tone {
    param([double]$FreqHz, [int]$DurationMs, [double]$Amp = 0.70)
    $samples = [int][Math]::Round($SampleRate * ($DurationMs / 1000.0))
    $rampLen = [Math]::Min(60, [Math]::Floor($samples / 4))
    for ($n = 0; $n -lt $samples; $n++) {
        $t = $n / [double]$SampleRate
        $env = 1.0
        if ($rampLen -gt 0) {
            if ($n -lt $rampLen) { $env = $n / [double]$rampLen }
            elseif ($n -gt ($samples - $rampLen)) { $env = ($samples - $n) / [double]$rampLen }
        }
        $valDouble = [Math]::Sin(2.0 * [Math]::PI * $FreqHz * $t) * 32767.0 * $Amp * $env
        $sample    = [int16][Math]::Max(-32768, [Math]::Min(32767, [Math]::Round($valDouble)))
        $bw.Write($sample)
    }
}

try {
    # Sync Preamble: 432 Hz (180ms) -> 528 Hz (220ms) -> Guard Silence (40ms)
    Add-Tone -FreqHz 432.0 -DurationMs 180 -Amp $Amplitude
    Add-Tone -FreqHz 528.0 -DurationMs 220 -Amp $Amplitude
    Add-Tone -FreqHz 0.0   -DurationMs 40  -Amp 0.0

    # 256-bit Bell-202 FSK Stream (1200 Hz = 0, 2200 Hz = 1)
    foreach ($b in $bitStr.ToString().ToCharArray()) {
        $f = if ($b -eq '1') { 2200.0 } else { 1200.0 }
        Add-Tone -FreqHz $f -DurationMs $BitMs -Amp $Amplitude
    }

    # End-of-Frame Harmonic Chime (864 Hz) + Tail Silence
    Add-Tone -FreqHz 864.0 -DurationMs 160 -Amp $Amplitude
    Add-Tone -FreqHz 0.0   -DurationMs 80  -Amp 0.0

    $pcmBytes = $ms.ToArray()
}
finally {
    $bw.Dispose()
    $ms.Dispose()
}

$fs  = [System.IO.File]::Open($WavOut, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
$wtr = New-Object System.IO.BinaryWriter($fs)
try {
    $wtr.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $wtr.Write([int32](36 + $pcmBytes.Length))
    $wtr.Write([System.Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
    $wtr.Write([int32]16)
    $wtr.Write([int16]1)
    $wtr.Write([int16]1)
    $wtr.Write([int32]$SampleRate)
    $wtr.Write([int32]($SampleRate * 2))
    $wtr.Write([int16]2)
    $wtr.Write([int16]16)
    $wtr.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $wtr.Write([int32]$pcmBytes.Length)
    $wtr.Write($pcmBytes)
}
finally {
    $wtr.Dispose()
    $fs.Dispose()
}

Write-Host "[ACOUSTIC 256-BIT TX] Pulse #$pulses | Full Seal: 0x$sealHex | WAV: $WavOut" -ForegroundColor Cyan

if (-not $NoPlay) {
    $player = New-Object System.Media.SoundPlayer($WavOut)
    try {
        $player.PlaySync()
    }
    finally {
        $player.Dispose()
    }
}