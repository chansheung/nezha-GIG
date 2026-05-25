#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; & "C:\Go\bin\go.exe" build -o F:\nezha\agent\nezha-agent.exe ./cmd/agent
echo "\n[flowcraft:exit:$?]"