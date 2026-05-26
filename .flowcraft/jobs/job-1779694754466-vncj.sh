#!/bin/bash
$baseDir = "C:\Users\well\AppData\Local\Temp\opencode"
$ProgressPreference = 'SilentlyContinue'
Write-Host "Fetching latest version tag..."
$releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/anomalyco/opencode/releases/latest" -UseBasicParsing
$version = $releaseInfo.tag_name -replace '^v',''
Write-Host "Latest version: $version"
$downloadUrl = "https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-x64.tar.gz"
Write-Host "Downloading from: $downloadUrl"
Invoke-WebRequest -Uri $downloadUrl -OutFile "$baseDir\opencode-linux-x64.tar.gz" -UseBasicParsing
if (Test-Path "$baseDir\opencode-linux-x64.tar.gz") {
    $size = (Get-Item "$baseDir\opencode-linux-x64.tar.gz").Length / 1MB
    Write-Host "Download complete! Size: $([math]::Round($size, 2)) MB"
} else {
    Write-Host "Download FAILED!"
}
echo "\n[flowcraft:exit:$?]"