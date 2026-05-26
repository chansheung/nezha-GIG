#!/bin/bash
wsl -e bash /mnt/c/Users/well/AppData/Local/Temp/opencode/setup_wsl.sh 2>&1 | Out-String
echo "\n[flowcraft:exit:$?]"