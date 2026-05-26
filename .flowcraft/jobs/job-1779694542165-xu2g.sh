#!/bin/bash
$ErrorActionPreference = "SilentlyContinue"
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "C:\Program Files\WSL\wsl.exe"
$pinfo.Arguments = "-d Ubuntu -- bash -c ""export PATH=$HOME/.opencode/bin:$PATH; curl -fsSL https://opencode.ai/install | bash 2>&1"""
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$pinfo.StandardErrorEncoding = [System.Text.Encoding]::Default
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()
Write-Host "Exit: $($p.ExitCode)"
Write-Host "=== STDOUT ==="
Write-Host $stdout
if ($stderr) { Write-Host "=== STDERR ==="; Write-Host $stderr }
echo "\n[flowcraft:exit:$?]"