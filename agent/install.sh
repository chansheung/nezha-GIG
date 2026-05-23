#!/bin/bash
set -e

# ============================================
# Nezha Agent 自定义版 - 安装脚本
# 支持全新安装和替换安装
# ============================================

AGENT_DIR="/opt/nezha/agent"
BINARY="$AGENT_DIR/nezha-agent"
CONFIG="$AGENT_DIR/config.yml"
SERVICE_FILE="/etc/systemd/system/nezha-agent.service"
CUSTOM_BINARY="$(dirname "$0")/nezha-agent"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[*]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# 检查二进制是否存在
if [ ! -f "$CUSTOM_BINARY" ]; then
    error "未找到 nezha-agent 文件，请确保与本脚本在同一目录"
    exit 1
fi

# 检查是否已安装
if [ -f "$BINARY" ] || [ -f "$CONFIG" ] || [ -f "$SERVICE_FILE" ]; then
    warn "检测到已存在的 agent 安装，将进行替换升级..."
    HAS_EXISTING=true
else
    info "全新安装..."
    HAS_EXISTING=false
fi

# ---------- 配置 ----------
if [ ! -f "$CONFIG" ]; then
    echo ""
    warn "请输入 Dashboard 连接信息："

    # 从环境变量读取或手动输入
    SERVER="${NZ_SERVER:-}"
    SECRET="${NZ_CLIENT_SECRET:-}"
    TLS="${NZ_TLS:-false}"

    if [ -z "$SERVER" ]; then
        read -p "  服务器地址 (例如 172.30.0.10:8008): " SERVER
    fi
    if [ -z "$SECRET" ]; then
        read -p "  Client Secret: " SECRET
    fi

    # 创建目录
    sudo mkdir -p "$AGENT_DIR"

    # 写入配置
    sudo tee "$CONFIG" > /dev/null << EOF
client_secret: $SECRET
server: $SERVER
tls: $TLS
EOF
    info "配置已写入 $CONFIG"
else
    warn "使用现有配置: $CONFIG"
fi

# ---------- 替换二进制 ----------
info "安装 agent 二进制..."
sudo mkdir -p "$AGENT_DIR"
if [ -f "$BINARY" ]; then
    sudo cp "$BINARY" "$BINARY.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null && \
        warn "原二进制已备份"
fi
sudo bash -c "cat '$CUSTOM_BINARY' > '$BINARY'"
sudo chmod +x "$BINARY"
info "二进制已安装"

# ---------- 创建 systemd 服务 ----------
if [ ! -f "$SERVICE_FILE" ]; then
    info "创建 systemd 服务..."
    sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=哪吒监控 Agent
ConditionFileIsExecutable=/opt/nezha/agent/nezha-agent
After=network.target

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/opt/nezha/agent/nezha-agent -c /opt/nezha/agent/config.yml
WorkingDirectory=/opt/nezha/agent
Restart=always
RestartSec=120
EnvironmentFile=-/etc/sysconfig/nezha-agent

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    info "systemd 服务已创建"
else
    warn "服务文件已存在"
fi

# ---------- 启动服务 ----------
info "停止旧服务..."
sudo systemctl kill nezha-agent.service 2>/dev/null || true
sleep 1

info "启动服务..."
sudo systemctl enable nezha-agent.service 2>/dev/null || true
sudo systemctl start nezha-agent.service

sleep 3
if systemctl is-active --quiet nezha-agent.service; then
    info "服务运行中！等待 Dashboard 上线..."
    echo ""
    echo "  查看状态: sudo systemctl status nezha-agent.service"
    echo "  查看日志: sudo journalctl -u nezha-agent --no-pager -n 20"
    echo "  调试运行: sudo NZ_DEBUG=true $BINARY -c $CONFIG"
else
    error "服务启动失败，查看日志:"
    echo "  sudo journalctl -u nezha-agent --no-pager -n 30"
    exit 1
fi
