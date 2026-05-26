#!/bin/bash
copy F:\nezha\agent\install.ps1 F:\nezha\release_temp\install.ps1; if ($?) { Write-Host "copy install.ps1 OK" }
echo "\n[flowcraft:exit:$?]"