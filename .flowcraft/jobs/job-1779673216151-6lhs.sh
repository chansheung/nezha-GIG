#!/bin/bash
Remove-Item -Recurse -Force "F:\nezha\agent_build_temp" -ErrorAction SilentlyContinue; echo "Step 1 done: cleaned old build dir"
echo "\n[flowcraft:exit:$?]"