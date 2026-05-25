#!/bin/bash
copy F:\nezha\agent\nezha-agent.exe F:\nezha\release_temp\nezha-agent.exe; if ($?) { copy F:\nezha\agent\install.ps1 F:\nezha\release_temp\install.ps1 }; if ($?) { copy F:\nezha\agent\temperature_windows.go F:\nezha\release_temp\temperature_windows.go }; if ($?) { copy F:\nezha\agent\temperature_linux.go F:\nezha\release_temp\temperature_linux.go }
echo "\n[flowcraft:exit:$?]"