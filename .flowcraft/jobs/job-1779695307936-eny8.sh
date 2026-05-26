#!/bin/bash
$ErrorActionPreference = "SilentlyContinue"
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "C:\Program Files\WSL\wsl.exe"
$pinfo.Arguments = "-d Ubuntu -- bash -c ""curl -sI -L --connect-timeout 10 https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz 2>&1 | grep -i content-length"""
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
Write-Host $stdout
echo "\n[flowcraft:exit:$?]"