#!/bin/bash
Get-ChildItem "F:\nezha\agent" -Name | Where-Object { $_ -like "*official*" -or $_ -like "*download*" }
echo "\n[flowcraft:exit:$?]"