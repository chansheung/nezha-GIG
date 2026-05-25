# Nezha Dashboard - Windows Install Script
# Run as Administrator

param(
    [string]$InstallDir = "C:\Program Files\NezhaDashboard"
)

$ErrorActionPreference = "Stop"

function Write-Info  { Write-Host "[+] $($args[0])" -ForegroundColor Green }
function Write-Warn  { Write-Host "[*] $($args[0])" -ForegroundColor Yellow }
function Write-Error { Write-Host "[-] $($args[0])" -ForegroundColor Red }

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "请以管理员身份运行此脚本"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$binary = Join-Path $scriptDir "nezha-dashboard.exe"
if (-not (Test-Path $binary)) {
    Write-Error "未找到 nezha-dashboard.exe"
    exit 1
}

$configDir = Join-Path $InstallDir "data"
$configFile = Join-Path $configDir "config.yaml"

if (Test-Path $configFile) {
    Write-Warn "检测到已有配置，将进行替换升级..."
    $hasConfig = $true
} else {
    Write-Info "全新安装，请准备配置..."
    $hasConfig = $false
}

# Create directories
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

# Install binary
Write-Info "安装 dashboard 二进制..."
if (Test-Path (Join-Path $InstallDir "nezha-dashboard.exe")) {
    $backupName = "nezha-dashboard.exe.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item (Join-Path $InstallDir "nezha-dashboard.exe") (Join-Path $InstallDir $backupName)
    Write-Warn "原二进制已备份为 $backupName"
}
Copy-Item $binary (Join-Path $InstallDir "nezha-dashboard.exe") -Force
Write-Info "二进制已安装"

# Create service
$serviceName = "NezhaDashboard"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Info "创建 Windows 服务..."
    New-Service -Name $serviceName `
        -BinaryPathName """$InstallDir\nezha-dashboard.exe""" `
        -DisplayName "哪吒监控 Dashboard" `
        -Description "Nezha Monitoring Dashboard - 监控管理面板" `
        -StartupType Automatic | Out-Null
    sc.exe failure $serviceName reset=86400 actions=restart/5000/restart/10000/restart/30000 | Out-Null
    Write-Info "服务已创建"
} else {
    Write-Warn "服务已存在"
}

if (-not $hasConfig) {
    Write-Host ""
    Write-Warn "首次安装，请编辑配置文件:"
    Write-Warn "  notepad $configFile"
    Write-Host ""
    Write-Warn "最小配置示例:"
    Write-Host @"
listen_port: 8008
site_name: "哪吒监控"
language: zh_CN
install_host: "你的IP:8008"
"@
    Write-Host ""
    Write-Info "编辑完成后启动服务: Start-Service $serviceName"
    Write-Info "然后访问 http://你的IP:8008 完成初始化"
} else {
    Write-Info "启动服务..."
    Stop-Service $serviceName -ErrorAction SilentlyContinue
    Start-Sleep 1
    Set-Service $serviceName -StartupType Automatic
    Start-Service $serviceName
    Start-Sleep 2
    $svc = Get-Service $serviceName
    if ($svc.Status -eq "Running") {
        Write-Info "服务运行中！"
    } else {
        Write-Error "服务启动失败"
    }
}
