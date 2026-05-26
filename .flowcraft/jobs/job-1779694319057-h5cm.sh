#!/bin/bash
$baseDir = "C:\Users\well\AppData\Local\Temp\opencode\wsl_ubuntu"
$installDir = "$baseDir\distro"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
Write-Host "Importing Ubuntu into WSL..."
Write-Host "  tarball: $baseDir\ubuntu-rootfs.tar.xz"
Write-Host "  install: $installDir"
& "C:\Windows\system32\wsl.exe" --import Ubuntu "$installDir" "$baseDir\ubuntu-rootfs.tar.xz" 2>&1
echo "\n[flowcraft:exit:$?]"