#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; go build -o nezha-agent.exe ./cmd/agent
echo "\n[flowcraft:exit:$?]"