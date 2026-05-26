#!/bin/bash
$wsl = "C:\Program Files\WSL\wsl.exe"; & $wsl -d Ubuntu-24.04 bash -c "curl -fsSL https://opencode.ai/install | bash"
echo "\n[flowcraft:exit:$?]"