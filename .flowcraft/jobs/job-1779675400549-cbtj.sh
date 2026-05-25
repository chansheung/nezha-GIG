#!/bin/bash
$env:GOOS="windows"; $env:GOARCH="amd64"; & "C:\Go\bin\go.exe" build -ldflags="-s -w -X main.arch=amd64 -X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3-custom" -o nezha-agent.exe ./cmd/agent 2>&1
echo "\n[flowcraft:exit:$?]"