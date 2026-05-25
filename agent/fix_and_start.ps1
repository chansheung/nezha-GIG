# Check if service exists
$svc = Get-Service NezhaAgent -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "Service exists, status: $($svc.Status)"
} else {
    Write-Host "Service does not exist"
}

# Stop the service if running
Stop-Service NezhaAgent -ErrorAction SilentlyContinue
Start-Sleep 1

# Replace with official binary
Write-Host "Copying official binary..."
Copy-Item "F:\nezha\agent\nezha-agent-official.exe" "C:\Program Files\NezhaAgent\nezha-agent.exe" -Force

# Remove old service and re-create
if ($svc) {
    Write-Host "Removing old service..."
    sc.exe delete NezhaAgent 2>&1 | Out-Null
    Start-Sleep 2
}

Write-Host "Creating service..."
$configFile = "C:\Program Files\NezhaAgent\config.yml"
$binPath = '"C:\Program Files\NezhaAgent\nezha-agent.exe" -c "' + $configFile + '"'

New-Service -Name NezhaAgent `
    -BinaryPathName $binPath `
    -DisplayName "Nezha Agent" `
    -Description "Nezha Monitoring Agent" `
    -StartupType Automatic | Out-Null

# Set recovery options
sc.exe failure NezhaAgent reset=86400 actions=restart/5000/restart/10000/restart/30000 | Out-Null

Write-Host "Starting service..."
Start-Service NezhaAgent
Start-Sleep 3

$svc = Get-Service NezhaAgent
Write-Host "Service status: $($svc.Status)"
