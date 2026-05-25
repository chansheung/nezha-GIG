#!/bin/bash
$env:Path = "C:\Go\bin;" + $env:Path; Set-Location -LiteralPath "C:\Users\well\AppData\Local\Temp\opencode\test_temp"; go compile ./temperature/ 2>&1
echo "\n[flowcraft:exit:$?]"