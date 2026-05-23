# Nezha Monitoring 自定义版

> 基于 [nezhahq/nezha](https://github.com/nezhahq/nezha) 和 [nezhahq/agent](https://github.com/nezhahq/agent) 修改
> 上游版本: v2.0.3

## 功能修改

### Dashboard (管理面板)
- **GPU 面板增强**：在原有 GPU 利用率基础上，增加显存使用量显示（已用 / 总量）
- 需配合自定义 Agent 使用

### Agent (`temperature.go`)

#### 1. NVMe 温度显示挂载点名
SSD 温度传感器默认显示为 `nvme_sensor_1`，无法区分是哪个硬盘。
修改后显示为 `/mnt` 目录下的挂载点名称，例如 `m2_8t_1_sensor_1`、`nvme2t_2_composite`。

#### 2. RAID0 成员盘自动识别
NVMe 硬盘作为 mdadm RAID0 成员时，自动解析所属 RAID 设备的挂载点。
例如 `md1` → `/mnt/m2_16t` → 传感器显示为 `m2_16t_sensor_1`。

#### 3. CPU 温度名称简化
- `k10temp_tctl` → `CPU`
- `k10temp_tccd1` → `CPU_1`

#### 4. GPU 温度 + 显存采集
通过 `nvidia-smi` 采集 NVIDIA GPU 温度和显存使用量。

### 传感器名称对照

| 传感器 | 含义 |
|--------|------|
| `挂载点名_composite` | NVMe 硬盘综合温度 |
| `挂载点名_sensor_1` | NVMe 控制器温度 |
| `挂载点名_sensor_2` | NAND 颗粒温度 |
| `CPU` | CPU 整体温度 (AMD k10temp tctl) |
| `CPU_N` | CPU 第 N 个 CCD 温度 |
| `GPU_0` / `GPU_1` | GPU 温度 |
| `GPU_0_mem_used` | GPU 已用显存 (MiB) |
| `GPU_0_mem_total` | GPU 总显存 (MiB) |

## 安装要求

- 支持 **Linux amd64** 架构
- Dashboard 和 Agent 均编译为静态 Go 二进制，无外部依赖
- GPU 功能需要 NVIDIA 显卡驱动（nvidia-smi）

## 下载

从 [Releases](https://github.com/chansheung/nezha-GIG/releases) 页面下载最新版本的压缩包：

| 包名 | 包含内容 |
|------|---------|
| `nezha-dashboard-v0.0.1.tar.gz` | Dashboard 二进制 + 一键安装脚本 |
| `nezha-agent-v0.0.1.tar.gz` | Agent 二进制 + 一键安装脚本 + 温度源码 |

## 安装方法

### Dashboard

```bash
# 下载并解压
tar xzf nezha-dashboard-v0.0.1.tar.gz
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

### Agent

```bash
# 下载并解压
tar xzf nezha-agent-v0.0.1.tar.gz
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

### 查看状态

```bash
# Dashboard
sudo systemctl status nezha-dashboard.service
sudo journalctl -u nezha-dashboard --no-pager -n 20

# Agent
sudo systemctl status nezha-agent.service
sudo journalctl -u nezha-agent --no-pager -n 20
```

## 自行编译

### Agent
```bash
git clone -b v2.0.3 https://github.com/nezhahq/agent.git
cp temperature.go agent/pkg/monitor/temperature/
cd agent
go build -ldflags="-X github.com/nezhahq/agent/pkg/monitor.Version=v2.0.3" \
  -o nezha-agent ./cmd/agent
```

### Dashboard
```bash
git clone -b master https://github.com/nezhahq/nezha.git
cd nezha
# 构建前端请参考上游文档
go build -o nezha-dashboard ./cmd/dashboard
```

## 许可证

上游项目基于 Apache 2.0 开源，本修改版本同样遵循 Apache 2.0。
