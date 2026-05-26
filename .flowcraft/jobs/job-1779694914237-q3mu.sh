#!/bin/bash
$ErrorActionPreference = "SilentlyContinue"
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "C:\Program Files\WSL\wsl.exe"
$pinfo.Arguments = "-d Ubuntu -- bash -c ""mkdir -p `$HOME/.opencode/bin; curl -fsSL -o /tmp/opencode.tar.gz https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-x64.tar.gz; ls -la /tmp/opencode.tar.gz"""
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
Write-Host "STDOUT: $stdout"
if ($stderr) { Write-Host "STDERR: $stderr" }
echo "\n[flowcraft:exit:$?]"