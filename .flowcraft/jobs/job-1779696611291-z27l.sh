#!/bin/bash
# Let me check if maybe the Windows version is too old for this WSL version
# Build 19045 = Windows 10 22H2
# WSL Store version 2.7.3.0 should work on this build

# Let me check if the Windows optional feature "VirtualMachinePlatform" is enabled
# This is required for WSL2
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform 2>$null
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux 2>$null
echo "\n[flowcraft:exit:$?]"