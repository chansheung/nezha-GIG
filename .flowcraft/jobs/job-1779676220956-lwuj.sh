#!/bin/bash
Copy-Item -LiteralPath "F:\nezha\agent\install.ps1" -Destination "F:\nezha\release_temp\install.ps1"; if ($?) { Write-Host "install.ps1 copied successfully" }
echo "\n[flowcraft:exit:$?]"