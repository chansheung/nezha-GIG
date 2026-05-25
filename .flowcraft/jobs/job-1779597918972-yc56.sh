#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; go build -o nezha-agent.exe ./cmd/agent 2>&1
echo "\n[flowcraft:exit:$?]"