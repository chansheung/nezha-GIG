#!/bin/bash
$ErrorActionPreference = "SilentlyContinue"; $result = curl.exe -L -v -o NUL "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz" 2>&1; $result | Select-Object -Last 20
echo "\n[flowcraft:exit:$?]"