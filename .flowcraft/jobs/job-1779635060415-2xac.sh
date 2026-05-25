#!/bin/bash
choco install golang -y --no-progress 2>&1 | Select-String -Pattern "error|successfully|already|installed" -SimpleMatch
echo "\n[flowcraft:exit:$?]"