#!/bin/bash
choco install golang --yes --no-progress 2>&1
echo "\n[flowcraft:exit:$?]"