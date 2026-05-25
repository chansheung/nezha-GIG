#!/bin/bash
cmd /c "set GOOS=windows && set GOARCH=amd64 && set PATH=C:\Go\bin;%PATH% && cd /d F:\nezha\agent_upstream && go build -o nezha-agent.exe ./cmd/agent 2>&1"
echo "\n[flowcraft:exit:$?]"