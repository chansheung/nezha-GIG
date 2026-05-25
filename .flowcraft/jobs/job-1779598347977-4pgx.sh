#!/bin/bash
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "C:\Users\well\AppData\Local\Temp\opencode\build.bat" -Wait -NoNewWindow
echo "\n[flowcraft:exit:$?]"