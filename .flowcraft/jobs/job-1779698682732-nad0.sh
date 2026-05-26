#!/bin/bash
& "C:\Program Files\WSL\wsl.exe" -d Ubuntu-24.04 bash -c "cp /mnt/c/Users/well/AppData/Local/Temp/opencode/install_all.sh /tmp/install_all.sh && bash /tmp/install_all.sh"
echo "\n[flowcraft:exit:$?]"