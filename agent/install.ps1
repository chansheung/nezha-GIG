# Nezha Agent Custom - Windows Install Script
# Run as Administrator

param(
    [string]$Server,
    [string]$ClientSecret,
    [switch]$Tls = $false,
    [switch]$DisableGpu,
    [switch]$DisableTemperature,
    [string]$InstallDir = "C:\Program Files\NezhaAgent"
)

$ErrorActionPreference = "Stop"

function Write-Info  { Write-Host "[+] $($args[0])" -ForegroundColor Green }
function Write-Warn  { Write-Host "[*] $($args[0])" -ForegroundColor Yellow }
function Write-Error { Write-Host "[-] $($args[0])" -ForegroundColor Red }

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "请以管理员身份运行此脚本"
    exit 1
}

# Check if binary exists
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$binary = Join-Path $scriptDir "nezha-agent.exe"
if (-not (Test-Path $binary)) {
    Write-Error "未找到 nezha-agent.exe，请确保与本脚本在同一目录"
    exit 1
}

# Check for existing installation
$configFile = Join-Path $InstallDir "config.yml"
$existingInstall = (Test-Path $InstallDir) -and (Test-Path $configFile)

if ($existingInstall) {
    Write-Warn "检测到已存在的安装，将进行替换升级..."
} else {
    Write-Info "全新安装..."
}

# Configuration
if (-not (Test-Path $configFile)) {
    if (-not $Server) {
        $Server = Read-Host "请输入 Dashboard 地址 (例如 192.168.1.100:8008)"
    }
    if (-not $ClientSecret) {
        $ClientSecret = Read-Host "请输入 Client Secret"
    }

    # Create install directory
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

    # Write config
    $gpuEnabled = if (-not $DisableGpu) { "true" } else { "false" }
    $tempEnabled = if (-not $DisableTemperature) { "true" } else { "false" }
    
    $configContent = @"
client_secret: $ClientSecret
server: $Server
tls: $Tls
gpu: $gpuEnabled
temperature: $tempEnabled
"@
    Set-Content -Path $configFile -Value $configContent -Encoding UTF8
    Write-Info "配置已写入 $configFile"
} else {
    Write-Warn "使用现有配置: $configFile"
}

# Install binary
Write-Info "安装 agent 二进制..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
if (Test-Path (Join-Path $InstallDir "nezha-agent.exe")) {
    $backupName = "nezha-agent.exe.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item (Join-Path $InstallDir "nezha-agent.exe") (Join-Path $InstallDir $backupName)
    Write-Warn "原二进制已备份为 $backupName"
}
Copy-Item $binary (Join-Path $InstallDir "nezha-agent.exe") -Force
Write-Info "二进制已安装"

# Create Windows Service
$serviceName = "NezhaAgent"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Info "创建 Windows 服务..."
    New-Service -Name $serviceName `
        -BinaryPathName """$InstallDir\nezha-agent.exe"" -c ""$configFile""" `
        -DisplayName "哪吒监控 Agent" `
        -Description "Nezha Monitoring Agent - 系统监控客户端" `
        -StartupType Automatic | Out-Null

    # Set recovery options (restart on failure)
    sc.exe failure $serviceName reset=86400 actions=restart/5000/restart/10000/restart/30000 | Out-Null

    Write-Info "Windows 服务已创建: $serviceName"
} else {
    Write-Warn "服务已存在: $serviceName"
}

# Start service
Write-Info "停止旧服务..."
Stop-Service $serviceName -ErrorAction SilentlyContinue
Start-Sleep 1

Write-Info "启动服务..."
Set-Service $serviceName -StartupType Automatic
Start-Service $serviceName

Start-Sleep 3
$service = Get-Service -Name $serviceName
if ($service.Status -eq "Running") {
    Write-Info "服务运行中！"
    Write-Host ""
    Write-Host "  查看状态: Get-Service $serviceName"
    Write-Host "  查看日志: Get-EventLog -LogName Application -Source nezha-agent -Newest 20"
    Write-Host "  调试运行: $InstallDir\nezha-agent.exe -c $configFile"
} else {
    Write-Error "服务启动失败，状态: $($service.Status)"
    Write-Host "  查看系统事件查看器获取更多信息"
    exit 1
}
