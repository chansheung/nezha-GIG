# Nezha Monitoring 自定义版

> 基于 [nezhahq/nezha](https://github.com/nezhahq/nezha) 和 [nezhahq/agent](https://github.com/nezhahq/agent) 修改
> 上游版本: v2.0.3 (✅ v0.0.4 已包含 CVE-2026-53519 修复)

## ⚠️ 安全公告 (CVE-2026-53519)

> **本仓库基于上游 v2.0.3，受 CVE-2026-53519 路径穿越漏洞影响 (CVSS 9.1)。**
> 漏洞允许未认证读取 `config.yaml`、`sqlite.db` 等敏感文件。
> 
> **修复方案**: 采用**定向补丁**（不升级版本）——仅在 v2.0.3 源码上应用路径穿越修复，
> 完整保留现有行为与自定义（含 GPU 面板）。详见 [build/README.md](build/README.md)。
> 
> ```bash
> cd build && bash build.sh   # 需要 Docker，产出 Linux amd64 二进制
> ```
> 
> **保留 GPU 面板**: 构建前运行 `./build/extract-frontend.sh http://你的Dashboard:8008`
> 提取现有自定义前端，`build.sh` 会自动使用。
> 
> 临时缓解: 在 Nginx 反代层加载 [dashboard/nginx-security.conf](dashboard/nginx-security.conf)。

## ⚠️ Windows 版本已知问题

> **Windows 版本存在异常资源占用问题（未修复）**
> 
> 建议生产环境使用 Linux 版本。Windows 版本仅供测试。

## 功能修改

### Dashboard (管理面板)
- **GPU 面板增强**：在原有 GPU 利用率基础上，增加显存使用量显示（已用 / 总量）
- 需配合自定义 Agent 使用

### Agent (`temperature`)

#### 1. NVMe 温度显示挂载点名 (Linux)
SSD 温度传感器默认显示为 `nvme_sensor_1`，无法区分是哪个硬盘。
修改后显示为 `/mnt` 目录下的挂载点名称，例如 `m2_8t_1_sensor_1`、`nvme2t_2_composite`。

#### 2. RAID0 成员盘自动识别 (Linux)
NVMe 硬盘作为 mdadm RAID0 成员时，自动解析所属 RAID 设备的挂载点。
例如 `md1` → `/mnt/m2_16t` → 传感器显示为 `m2_16t_sensor_1`。

#### 3. CPU 温度名称简化 (Linux)
- `k10temp_tctl` → `CPU`
- `k10temp_tccd1` → `CPU_1`

#### 4. GPU 温度 + 显存采集 (Linux / Windows)
通过 `nvidia-smi` 采集 NVIDIA GPU 温度和显存使用量。

#### 5. Windows 温度监控（amd64）
- **GPU 温度 + 显存**：通过 `nvidia-smi` 采集 NVIDIA GPU 温度和显存使用量
- **磁盘温度**：通过 PowerShell `Get-PhysicalDisk | Get-StorageReliabilityCounter` 获取硬盘温度，显示硬盘型号名（如 `sn580`、`ST4000DM004`）
- **CPU 温度**：桌面平台通常无 ACPI 热区传感器，暂不支持

### 传感器名称对照

#### Linux

| 传感器 | 含义 |
|--------|------|
| `挂载点名_composite` | NVMe 硬盘综合温度 |
| `挂载点名_sensor_1` | NVMe 控制器温度 |
| `挂载点名_sensor_2` | NAND 颗粒温度 |
| `CPU` | CPU 整体温度 (AMD k10temp tctl) |
| `CPU_N` | CPU 第 N 个 CCD 温度 |
| `GPU_0` / `GPU_1` | GPU 温度 |
| `GPU_0_mem` | GPU 显存使用率 (%) |
| `GPU_0_mem_used` | GPU 已用显存 (MiB) |
| `GPU_0_mem_total` | GPU 总显存 (MiB) |

#### Windows

| 传感器 | 含义 |
|--------|------|
| `硬盘型号名` | 硬盘温度，如 `sn580`、`ST4000DM004` 等 |
| `GPU_0` / `GPU_1` | GPU 温度 |
| `GPU_0_mem` | GPU 显存使用率 (%) |
| `GPU_0_mem_used` | GPU 已用显存 (MiB) |
| `GPU_0_mem_total` | GPU 总显存 (MiB) |

## 安装要求

- 支持 **Linux amd64** 和 **Windows amd64** 架构
- Dashboard 和 Agent 均编译为静态 Go 二进制，无外部依赖
- GPU 功能需要 NVIDIA 显卡驱动（nvidia-smi），建议安装到系统 PATH
- Windows Agent 需要以管理员权限运行（安装服务、查询 WMI/PowerShell）

## 测试平台

### Windows amd64

> **⚠️ Windows 版本存在异常资源占用问题（未修复）**

| 项目 | 详情 |
|------|------|
| 操作系统 | Windows 11 |
| CPU | Intel Core i9-10920X @ 3.50GHz (12核24线程) |
| GPU | NVIDIA GeForce RTX 3080 (10GB GDDR6X) |
| 显卡驱动 | NVIDIA-SMI 576.52 / CUDA 12.9 |
| 磁盘 | NVMe SSD + SATA HDD 混合环境 |
| 架构 | amd64 (x86_64) |
| 测试状态 | ✅ 通过 |

## 下载

从 [Releases](https://github.com/chansheung/nezha-GIG/releases) 页面下载最新版本的压缩包：

| 包名 | 包含内容 |
|------|---------|
| `nezha-dashboard-v0.0.4.tar.gz` | Dashboard 二进制 + Linux 安装脚本 |
| `nezha-agent-v0.0.4.tar.gz` | Agent 二进制 + Linux 安装脚本 + 温度源码 |
| `nezha-dashboard-v0.0.4-windows-amd64.zip` | Dashboard 二进制 + Windows 安装脚本 |
| `nezha-agent-v0.0.4-windows-amd64.zip` | Agent 二进制 + Windows 安装脚本 + 温度源码 |

## 安装方法

### Dashboard (Linux)

```bash
# 下载并解压
tar xzf nezha-dashboard-v0.0.4.tar.gz
cd dashboard

# 一键安装
sudo bash install.sh
```

脚本会：
1. 创建 `/opt/nezha/dashboard/` 目录
2. 安装 Dashboard 二进制
3. 创建 systemd 服务
4. 首次安装提示编辑配置文件

首次安装后需编辑配置文件：

```bash
sudo vim /opt/nezha/dashboard/data/config.yaml
```

最小配置示例：

```yaml
listen_port: 8008
site_name: "哪吒监控"
language: zh_CN
install_host: "你的IP:8008"
```

编辑完成后启动服务：

```bash
sudo systemctl start nezha-dashboard.service
```

访问 `http://你的IP:8008` 完成初始化。

### Agent (Linux)

```bash
# 下载并解压
tar xzf nezha-agent-v0.0.4.tar.gz
cd agent

# 一键安装（支持全新安装和替换升级）
sudo bash install.sh
```

脚本会提示输入 Dashboard 地址和 Client Secret，也可以通过环境变量预填：

```bash
sudo NZ_SERVER=your-server:8008 NZ_CLIENT_SECRET=your-secret bash install.sh
```

功能：
- ✅ 全新安装：自动创建配置、systemd 服务、启动 Agent
- ✅ 替换升级：备份原二进制、替换新版本、重启服务
- ✅ 保留现有配置（不会覆盖已有的 config.yml）

### Dashboard (Windows)

> **⚠️ Windows 版本存在异常资源占用问题（未修复）**

```powershell
# 下载并解压
Expand-Archive nezha-dashboard-v0.0.4-windows-amd64.zip -DestinationPath dashboard
cd dashboard

# 以管理员身份运行安装脚本
.\install.ps1
```

首次安装后编辑配置文件：

```powershell
notepad "C:\Program Files\NezhaDashboard\data\config.yaml"
```

编辑完成后启动服务：

```powershell
Start-Service NezhaDashboard
```

### Agent (Windows)

> **⚠️ Windows 版本存在异常资源占用问题（未修复）**

```powershell
# 下载并解压
Expand-Archive nezha-agent-v0.0.4-windows-amd64.zip -DestinationPath agent
cd agent

# 以管理员身份运行安装脚本
.\install.ps1
```

也可以通过参数预填连接信息：

```powershell
.\install.ps1 -Server "your-server:8008" -ClientSecret "your-secret"
```

**安装脚本会自动完成：**

1. 创建安装目录 `C:\Program Files\NezhaAgent\`
2. 写入配置文件 `config.yml`（含 `gpu: true`、`temperature: true`）
3. 复制 `nezha-agent.exe`
4. 注册 Windows 服务 `NezhaAgent`（开机自启）
5. 设置服务失败自动重启（5秒/10秒/30秒）
6. 启动服务

**若要禁用 GPU 或温度监控：**

```powershell
.\install.ps1 -Server "your-server:8008" -ClientSecret "your-secret" -DisableGpu -DisableTemperature
```

### 查看状态 (Linux)

```bash
# Dashboard
sudo systemctl status nezha-dashboard.service
sudo journalctl -u nezha-dashboard --no-pager -n 20

# Agent
sudo systemctl status nezha-agent.service
sudo journalctl -u nezha-agent --no-pager -n 20
```

### 查看状态 (Windows)

```powershell
# Dashboard
Get-Service NezhaDashboard

# Agent
Get-Service NezhaAgent

# 调试运行
& "C:\Program Files\NezhaAgent\nezha-agent.exe" -c "C:\Program Files\NezhaAgent\config.yml"
```

## 自行编译

### Agent (Linux)

```bash
git clone -b v2.0.3 https://github.com/nezhahq/agent.git
cd agent

# 复制自定义温度文件
cp /path/to/temperature_linux.go pkg/monitor/temperature/

# 注意：上游已有一个 temperature.go，需在第一行添加：
# //go:build !windows && !linux

GOOS=linux GOARCH=amd64 go build -ldflags="\
  -s -w \
  -X main.arch=amd64 \
  -X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3" \
  -o nezha-agent ./cmd/agent
```

### Agent (Windows)

```bash
git clone -b v2.0.3 https://github.com/nezhahq/agent.git
cd agent

# 复制自定义温度文件
cp /path/to/temperature_windows.go pkg/monitor/temperature/
cp /path/to/temperature_linux.go pkg/monitor/temperature/

# 注意：上游已有一个 temperature.go，需在第一行添加：
# //go:build !windows && !linux

GOOS=windows GOARCH=amd64 go build -ldflags="\
  -s -w \
  -X main.arch=amd64 \
  -X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3-custom" \
  -o nezha-agent.exe ./cmd/agent
```

> **注意**：`-X main.arch=amd64` 是必须的，否则 agent 启动时会报"与当前系统不匹配"错误。
> Windows 版本需要 `github.com/yusufpapurcu/wmi` 依赖，该包在上游 agent 的 `go.mod` 中已包含。

### Dashboard

```bash
git clone -b master https://github.com/nezhahq/nezha.git
cd nezha
# 构建前端请参考上游文档
go build -o nezha-dashboard ./cmd/dashboard
```

## 许可证

上游项目基于 Apache 2.0 开源，本修改版本同样遵循 Apache 2.0。
