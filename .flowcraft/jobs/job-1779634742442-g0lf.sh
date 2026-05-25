#!/bin/bash
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"F:\nezha\agent\install.ps1\" -Server \"172.30.0.10:8008\" -ClientSecret \"0y5RDcFV3BDwUbcgqn3mpLjiWYKQWV5H\"' -Wait; Write-Host 'Elevated process completed'"
echo "\n[flowcraft:exit:$?]"