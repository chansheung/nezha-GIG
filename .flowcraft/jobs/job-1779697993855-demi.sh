#!/bin/bash
$ErrorActionPreference = "Continue"; & "C:\Program Files\WSL\wsl.exe" --install -d Ubuntu-24.04 2>&1
echo "\n[flowcraft:exit:$?]"