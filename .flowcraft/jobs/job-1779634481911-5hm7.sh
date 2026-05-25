#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; go build -ldflags="-X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3-custom" -o nezha-agent.exe ./cmd/agent
echo "\n[flowcraft:exit:$?]"