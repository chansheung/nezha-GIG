#!/bin/bash
$wsl = "C:\Program Files\WSL\wsl.exe"
& $wsl bash -c "curl -fsSL https://opencode.ai/install | bash"
echo "\n[flowcraft:exit:$?]"