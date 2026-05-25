#!/bin/bash
& "C:\Go\bin\go.exe" version -m "F:\nezha\agent\nezha-agent.exe" 2>&1 | Select-String -Pattern "mod|build"
echo "\n[flowcraft:exit:$?]"