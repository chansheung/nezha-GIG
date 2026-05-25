#!/bin/bash
powershell -ExecutionPolicy Bypass -File "C:\Users\well\AppData\Local\Temp\opencode\build.ps1"
echo "\n[flowcraft:exit:$?]"