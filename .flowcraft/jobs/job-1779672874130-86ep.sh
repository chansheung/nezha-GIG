#!/bin/bash
$env:Path = "C:\Go\bin;" + $env:Path; $env:GOOS = "windows"; $env:GOARCH = "amd64"; Set-Location -LiteralPath "F:\nezha\agent_build_temp"; go build -o "F:\nezha\agent_build_temp\nezha-agent.exe" "./cmd/agent"
echo "\n[flowcraft:exit:$?]"