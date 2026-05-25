#!/bin/bash
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"F:\nezha\agent\install.ps1\"\" -Server \"\"172.30.0.10:8008\"\" -ClientSecret \"\"0y5RDcFV3BDwUbcgqn3mpLjiWYKQWV5H\"\"' -Wait -WindowStyle Hidden; Write-Host 'Done'"
echo "\n[flowcraft:exit:$?]"