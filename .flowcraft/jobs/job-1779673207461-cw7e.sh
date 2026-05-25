#!/bin/bash
if (Test-Path "F:\nezha\agent_build_temp") { Remove-Item -LiteralPath "F:\nezha\agent_build_temp" -Recurse -Force }; "Cleaned up old build directory (or it didn't exist)"
echo "\n[flowcraft:exit:$?]"