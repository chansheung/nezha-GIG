#!/bin/bash
$outLog = "C:\Users\well\AppData\Local\Temp\opencode\wsl_install_log.txt"; $scriptContent = 'chcp 65001 >nul 2>&1
wsl --install -d Ubuntu --no-launch > "' + $outLog + '" 2>&1
echo DONE >> "' + $outLog + '"
'; Set-Content -Path "C:\Users\well\AppData\Local\Temp\opencode\install_ubuntu.cmd" -Value $scriptContent -Encoding ASCII; Write-Host "Script created. Running elevated..."
echo "\n[flowcraft:exit:$?]"