$ErrorActionPreference = "Stop"
try {
    $svcName = "NezhaAgent"
    $binPath = '"C:\Program Files\NezhaAgent\nezha-agent.exe" -c "C:\Program Files\NezhaAgent\config.yml"'
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host "Creating service..."
        New-Service -Name $svcName -BinaryPathName $binPath -DisplayName "Nezha Agent" -Description "Nezha Monitoring Agent" -StartupType Automatic
        Write-Host "Setting recovery..."
        sc.exe failure $svcName reset=86400 actions=restart/5000/restart/10000/restart/30000
    } else {
        Write-Host "Service already exists"
    }
    Write-Host "Starting service..."
    Stop-Service $svcName -ErrorAction SilentlyContinue
    Start-Sleep 1
    Set-Service $svcName -StartupType Automatic
    Start-Service $svcName
    Start-Sleep 2
    $svc = Get-Service $svcName
    Write-Host "Status: $($svc.Status)"
} catch {
    Write-Host "ERROR: $_"
    exit 1
}
