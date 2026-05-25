#!/bin/bash
Remove-Item -LiteralPath "F:\nezha\agent_build_temp" -Recurse -Force; Write-Host "Cleaned up build temp directory"
echo "\n[flowcraft:exit:$?]"