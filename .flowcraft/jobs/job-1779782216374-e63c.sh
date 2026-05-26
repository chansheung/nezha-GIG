#!/bin/bash
Copy-Item -Path "F:\nezha\agent\install.ps1" -Destination "F:\nezha\release_temp\install.ps1" -Force
echo "\n[flowcraft:exit:$?]"