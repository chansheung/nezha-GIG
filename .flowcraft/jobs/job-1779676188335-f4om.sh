#!/bin/bash
Copy-Item -LiteralPath "F:\nezha\agent\install.ps1" -Destination "F:\nezha\release_temp\install.ps1"; if ($?) { Write-Host "Copied install.ps1" }
echo "\n[flowcraft:exit:$?]"