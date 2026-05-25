#!/bin/bash
$env:Path = "C:\Go\bin;" + $env:Path; Set-Location -LiteralPath "F:\nezha\agent_upstream"; $env:GOOS = "windows"; $env:GOARCH = "amd64"; go build -o nezha-agent.exe ./cmd/agent 2>&1 | Out-String
echo "\n[flowcraft:exit:$?]"