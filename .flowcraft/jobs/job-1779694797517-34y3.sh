#!/bin/bash
$ProgressPreference = 'SilentlyContinue'
$baseDir = "C:\Users\well\AppData\Local\Temp\opencode"
$url = "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz"
Write-Host "Downloading OpenCode v1.15.10 for Linux x64..."
Write-Host "URL: $url"
try {
    Invoke-WebRequest -Uri $url -OutFile "$baseDir\opencode-linux-x64.tar.gz" -UseBasicParsing
    $size = (Get-Item "$baseDir\opencode-linux-x64.tar.gz").Length / 1MB
    Write-Host "SUCCESS! Size: $([math]::Round($size, 2)) MB"
} catch {
    Write-Host "FAILED: $($_.Exception.Message)"
    Write-Host "StatusCode: $($_.Exception.Response.StatusCode)"
}
echo "\n[flowcraft:exit:$?]"