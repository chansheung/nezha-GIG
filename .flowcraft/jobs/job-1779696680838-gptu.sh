#!/bin/bash
# Let me try unregistering and re-registering the Ubuntu distro
# First, check if there are important things to backup
# Actually, let me try --install first to see if WSL can be repaired

# Let's try wsl --install --no-distribution to update the WSL platform
# Actually no, let's not break anything. Let me try one more thing:
# Run wsl with WSL_DEBUG=true to get more info

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "wsl.exe"
$psi.Arguments = "-e true"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$psi.EnvironmentVariables["WSL_DEBUG"] = "1"
$psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
$proc = [System.Diagnostics.Process]::Start($psi)
$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()
Write-Host "EXIT: $($proc.ExitCode)"
Write-Host "STDOUT: [$stdout]"
Write-Host "STDERR: [$stderr]"

# Also, let me check if maybe it's a Windows insider / version issue
[System.Environment]::OSVersion.Version
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
echo "\n[flowcraft:exit:$?]"