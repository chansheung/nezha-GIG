#!/bin/bash
$ws = "C:\Program Files\WSL\wsl.exe"; & $ws --install -d Ubuntu-24.04 2>&1
echo "\n[flowcraft:exit:$?]"