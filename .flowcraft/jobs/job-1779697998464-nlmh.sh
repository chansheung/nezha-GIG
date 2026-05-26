#!/bin/bash
$ErrorActionPreference = "Continue"; $output = & "C:\Program Files\WSL\wsl.exe" --install -d Ubuntu-24.04 2>&1; Write-Output $output
echo "\n[flowcraft:exit:$?]"