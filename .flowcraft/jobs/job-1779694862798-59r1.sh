#!/bin/bash
curl.exe -L -o "C:\Users\well\AppData\Local\Temp\opencode\opencode-linux-x64.tar.gz" "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz" 2>&1; Write-Host "EXIT: $LASTEXITCODE"
echo "\n[flowcraft:exit:$?]"