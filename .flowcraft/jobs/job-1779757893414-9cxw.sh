#!/bin/bash
Write-Output "Starting build..."; $env:GOOS="windows"; $env:GOARCH="amd64"; go build -ldflags="-s -w -X main.arch=amd64 -X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3-custom" -o nezha-agent.exe ./cmd/agent 2>&1
echo "\n[flowcraft:exit:$?]"