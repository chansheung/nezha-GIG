#!/bin/bash
$wsl = "C:\Program Files\WSL\wsl.exe"
& $wsl env -i HOME=/root USER=root bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts && node --version && npm --version'
echo "\n[flowcraft:exit:$?]"