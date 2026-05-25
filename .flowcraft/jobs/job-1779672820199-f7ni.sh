#!/bin/bash
$env:Path = "C:\Go\bin;" + $env:Path; $env:GOOS = "windows"; $env:GOARCH = "amd64"; go build -o F:\nezha\agent\nezha-agent.exe ./cmd/agent 2>&1
echo "\n[flowcraft:exit:$?]"