# Nezha Monitoring 自定义版

> 基于 [nezhahq/nezha](https://github.com/nezhahq/nezha) 和 [nezhahq/agent](https://github.com/nezhahq/agent) 修改
> 上游版本: v2.0.3

## 功能修改

### Dashboard
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

## 文件说明

```
nezha/
├── README.md
├── dashboard/
│   └── nezha-dashboard          # Dashboard 二进制 (linux amd64)
└── agent/
    ├── nezha-agent              # Agent 二进制 (linux amd64)
    ├── install.sh               # 一键安装脚本
    └── temperature.go           # 温度采集源码
```

## 安装要求

- 支持 **Linux amd64** 架构
- 需要 wget 或 curl
- Dashboard 和 Agent 均编译为静态 Go 二进制，无外部依赖

## 安装方法

### Dashboard

> 需要有现成的 SQLite 数据库或 MySQL 配置

```bash
# 1. 创建目录
sudo mkdir -p /opt/nezha/dashboard/data

# 2. 复制二进制
sudo bash -c 'cat ./nezha-dashboard > /opt/nezha/dashboard/app'
sudo chmod +x /opt/nezha/dashboard/app

# 3. 创建 systemd 服务
sudo tee /etc/systemd/system/nezha-dashboard.service << 'SERVICEEOF'
[Unit]
Description=Nezha Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/nezha/dashboard
ExecStart=/opt/nezha/dashboard/app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

# 4. 启动
sudo systemctl daemon-reload
sudo systemctl enable --now nezha-dashboard.service
```

### Agent

一键安装（全新安装或替换升级均可）：

```bash
cd agent/
sudo bash install.sh
```

脚本会提示输入 Dashboard 地址和 Client Secret，你也可以通过环境变量预填：

```bash
sudo NZ_SERVER=your-server:8008 NZ_CLIENT_SECRET=your-secret bash install.sh
```

功能：
- ✅ 全新安装：自动创建配置、systemd 服务、启动 agent
- ✅ 替换升级：备份原二进制、替换新版本、重启服务
- ✅ 保留现有配置（不会覆盖已有的 config.yml）

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
