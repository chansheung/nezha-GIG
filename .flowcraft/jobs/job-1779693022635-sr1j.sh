#!/bin/bash
wsl bash -c "which opencode 2>/dev/null; if [ $? -eq 0 ]; then echo 'OpenCode already installed'; opencode --version; else echo 'Installing OpenCode...'; curl -fsSL https://opencode.ai/install | bash; fi"
echo "\n[flowcraft:exit:$?]"