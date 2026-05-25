#!/bin/bash
go build -ldflags="-s -w -X main.arch=amd64 -X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3-custom" -o nezha-agent.exe ./cmd/agent
echo "\n[flowcraft:exit:$?]"