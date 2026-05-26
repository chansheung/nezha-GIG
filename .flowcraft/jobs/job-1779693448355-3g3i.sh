#!/bin/bash
# Let me try to install Ubuntu from the command line
# First, check if wsl --install -d Ubuntu works
$script = @'
# Try to install Ubuntu
wsl --install -d Ubuntu --no-launch 2>&1 | Out-File "C:\Users\well\AppData\Local\Temp\opencode\wsl_install.txt" -Encoding UTF8
'@
Set-Content -Path "C:\Users\well\AppData\Local\Temp\opencode\install_ubuntu.ps1" -Value $script -Encoding UTF8
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File C:\Users\well\AppData\Local\Temp\opencode\install_ubuntu.ps1" -Verb RunAs -Wait
Start-Sleep -Seconds 5
if (Test-Path "C:\Users\well\AppData\Local\Temp\opencode\wsl_install.txt") {
    Get-Content "C:\Users\well\AppData\Local\Temp\opencode\wsl_install.txt"
} else {
    Write-Host "No output file created"
}
echo "\n[flowcraft:exit:$?]"