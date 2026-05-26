#!/bin/bash
go version -m "F:\nezha\agent\nezha-agent.exe" 2>&1 | Select-String -Pattern "mod|build|arch"
echo "\n[flowcraft:exit:$?]"