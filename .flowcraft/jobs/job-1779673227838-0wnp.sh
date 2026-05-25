#!/bin/bash
Remove-Item -Recurse -Force "F:\nezha\agent_build_temp" -ErrorAction SilentlyContinue; Write-Output "Old build directory cleaned."
echo "\n[flowcraft:exit:$?]"