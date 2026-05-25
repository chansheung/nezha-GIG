#!/bin/bash
Copy-Item -LiteralPath "F:\nezha\agent\install.ps1" -Destination "F:\nezha\release_temp\install.ps1"; Get-ChildItem -LiteralPath "F:\nezha\release_temp"
echo "\n[flowcraft:exit:$?]"