#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; & "C:\Go\bin\go.exe" build -o F:\nezha\agent\nezha-agent.exe ./cmd/agent 2>&1
echo "\n[flowcraft:exit:$?]"