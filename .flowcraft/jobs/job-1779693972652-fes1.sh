#!/bin/bash
$script = @'
$ErrorActionPreference = "Continue"
$output = & cmd /c "wsl --install -d Ubuntu 2>&1"
$output | Out-File "C:\Users\well\AppData\Local\Temp\opencode\ubuntu_install_result.txt" -Encoding utf8
'@
Set-Content -Path "C:\Users\well\AppData\Local\Temp\opencode\do_install_ubuntu.ps1" -Value $script -Encoding UTF8
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy","Bypass","-File","C:\Users\well\AppData\Local\Temp\opencode\do_install_ubuntu.ps1" -Verb RunAs -Wait
Start-Sleep -Seconds 3
Get-Content "C:\Users\well\AppData\Local\Temp\opencode\ubuntu_install_result.txt" -ErrorAction SilentlyContinue
echo "\n[flowcraft:exit:$?]"