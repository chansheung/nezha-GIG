#!/bin/bash
# The error is always the same - this looks like WSL is fundamentally broken
# Let me try to install WSL from scratch with admin
Start-Process -FilePath "powershell.exe" -ArgumentList "-Command","wsl --install --no-distribution" -Verb RunAs -Wait 2>&1
echo "\n[flowcraft:exit:$?]"