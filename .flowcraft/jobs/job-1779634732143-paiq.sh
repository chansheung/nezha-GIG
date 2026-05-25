#!/bin/bash
$logFile = "F:\nezha\agent\install_log.txt"
$scriptBlock = @"
cd 'F:\nezha\agent'
powershell -ExecutionPolicy Bypass -File 'F:\nezha\agent\install.ps1' -Server '172.30.0.10:8008' -ClientSecret '0y5RDcFV3BDwUbcgqn3mpLjiWYKQWV5H' *> '$logFile'
"@
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptBlock`"" -Wait
Get-Content $logFile -Raw
echo "\n[flowcraft:exit:$?]"