#!/bin/bash
& "C:\Program Files\WSL\wsl.exe" bash -c "curl -fsSL https://opencode.ai/install | bash"
echo "\n[flowcraft:exit:$?]"