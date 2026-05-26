#!/bin/bash
$w = "C:\Program Files\WSL\wsl.exe"; & $w --install -d Ubuntu-24.04 2>&1
echo "\n[flowcraft:exit:$?]"