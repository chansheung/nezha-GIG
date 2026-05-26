#!/bin/bash
$ErrorActionPreference = "Continue"
$outFile = "C:\Users\well\AppData\Local\Temp\opencode\opencode-linux-x64.tar.gz"
$url = "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz"
Write-Host "Downloading via .NET HttpClient..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
try {
    $wc.DownloadFile($url, $outFile)
    $size = (Get-Item $outFile).Length / 1MB
    Write-Host "SUCCESS! Size: $([math]::Round($size, 2)) MB"
} catch {
    Write-Host "FAILED: $($_.Exception.Message)"
    Write-Host "InnerException: $($_.Exception.InnerException.Message)"
}
echo "\n[flowcraft:exit:$?]"