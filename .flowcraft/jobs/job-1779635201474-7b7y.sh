#!/bin/bash
$url = "https://github.com/nezhahq/agent/releases/download/v2.0.3/nezha-agent_windows_amd64.zip"
$zip = "F:\nezha\agent\official_agent.zip"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Write-Host "Downloaded successfully"
echo "\n[flowcraft:exit:$?]"