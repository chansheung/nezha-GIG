#!/bin/bash
powershell -ExecutionPolicy Bypass -File F:\nezha\agent\install.ps1 -Server "172.30.0.10:8008" -ClientSecret "0y5RDcFV3BDwUbcgqn3mpLjiWYKQWV5H"
echo "\n[flowcraft:exit:$?]"