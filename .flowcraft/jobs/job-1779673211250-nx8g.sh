#!/bin/bash
if (Test-Path -LiteralPath "F:\nezha\agent_build_temp") { Remove-Item -LiteralPath "F:\nezha\agent_build_temp" -Recurse -Force; Write-Output "Cleaned old build directory" } else { Write-Output "No old build directory found" }
echo "\n[flowcraft:exit:$?]"