#!/bin/bash
cmd /c ""C:\Program Files\WSL\wsl.exe" -d Ubuntu-24.04 bash -c "curl -fsSL https://opencode.ai/install | bash""
echo "\n[flowcraft:exit:$?]"