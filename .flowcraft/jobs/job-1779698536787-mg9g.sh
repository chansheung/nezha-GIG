#!/bin/bash
$env:WSLPATH = "C:\Program Files\WSL\wsl.exe"; & $env:WSLPATH -d Ubuntu-24.04 bash -c "curl -fsSL https://opencode.ai/install | bash"
echo "\n[flowcraft:exit:$?]"