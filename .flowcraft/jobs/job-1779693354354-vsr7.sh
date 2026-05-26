#!/bin/bash
# The garbled error is always the same - maybe it's a known WSL issue.
# Let me try to install Ubuntu distro directly
# First, check available distros online
wsl --install -d Ubuntu --no-launch 2>&1 | Out-File "C:\Users\well\AppData\Local\Temp\opencode\wsl_install.txt" -Encoding utf8
Get-Content "C:\Users\well\AppData\Local\Temp\opencode\wsl_install.txt"
echo "\n[flowcraft:exit:$?]"