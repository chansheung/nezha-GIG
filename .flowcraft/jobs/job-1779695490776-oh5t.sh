#!/bin/bash
$ErrorActionPreference = "SilentlyContinue"
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "C:\Program Files\WSL\wsl.exe"
$pinfo.Arguments = "-d Ubuntu -- bash -c ""wget --timeout=30 --tries=1 -q -O /tmp/oc.tar.gz https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz 2>&1; echo EXIT_`$?; ls -la /tmp/oc.tar.gz 2>&1"""
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$pinfo.StandardErrorEncoding = [System.Text.Encoding]::Default
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
Write-Host "Exit: $($p.ExitCode)"
Write-Host "STDOUT: $stdout"
if ($stderr) { Write-Host "STDERR: $stderr" }
echo "\n[flowcraft:exit:$?]"