#!/bin/bash
$ProgressPreference = 'SilentlyContinue'
$outFile = "C:\Users\well\AppData\Local\Temp\opencode\opencode-linux-x64.tar.gz"
$url = "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz"
Write-Host "Downloading OpenCode v1.15.10..."
try {
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing -MaximumRedirection 5
    $size = (Get-Item $outFile).Length / 1MB
    Write-Host "SUCCESS! Size: $([math]::Round($size, 2)) MB"
} catch {
    Write-Host "FAILED: $($_.Exception.Message)"
}
echo "\n[flowcraft:exit:$?]"