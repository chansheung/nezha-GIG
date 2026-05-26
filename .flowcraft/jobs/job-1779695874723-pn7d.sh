#!/bin/bash
wsl -e bash /mnt/c/Users/well/AppData/Local/Temp/opencode/setup_wsl.sh 2>$null; if ($?) { wsl -e cat /tmp/wsl_setup_output.txt 2>$null }
echo "\n[flowcraft:exit:$?]"