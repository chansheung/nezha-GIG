$logFile = "F:\nezha\agent\install_log.txt"
$scriptBlock = [ScriptBlock]::Create(@"
cd 'F:\nezha\agent'
powershell -ExecutionPolicy Bypass -File 'F:\nezha\agent\install.ps1' -Server '172.30.0.10:8008' -ClientSecret '0y5RDcFV3BDwUbcgqn3mpLjiWYKQWV5H' *> '$logFile'
"@)
$proc = Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$($scriptBlock.ToString().Replace('"','\"'))`"" -Wait -PassThru
Write-Host "Exit code: $($proc.ExitCode)"
if (Test-Path $logFile) {
    Get-Content $logFile -Raw
} else {
    Write-Host "Log file not found"
}
