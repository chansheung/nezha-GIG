#!/bin/bash
set -e

DASHBOARD_DIR="/opt/nezha/dashboard"
BINARY="$DASHBOARD_DIR/app"
SERVICE_FILE="/etc/systemd/system/nezha-dashboard.service"
CUSTOM_BINARY="$(dirname "$0")/nezha-dashboard"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[*]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

if [ ! -f "$CUSTOM_BINARY" ]; then
    error "未找到 nezha-dashboard 文件，请确保与本脚本在同一目录"
    exit 1
fi

# 检查是否已有配置
if [ -f "$DASHBOARD_DIR/data/config.yaml" ]; then
    warn "检测到已有配置，将进行替换升级..."
    HAS_CONFIG=true
else
    info "全新安装，请准备配置..."
    HAS_CONFIG=false
fi

# 创建目录
info "创建目录..."
sudo mkdir -p "$DASHBOARD_DIR/data"

# 替换二进制
info "安装 dashboard 二进制..."
if [ -f "$BINARY" ]; then
    sudo cp "$BINARY" "$BINARY.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null && \
        warn "原二进制已备份"
fi
sudo bash -c "cat '$CUSTOM_BINARY' > '$BINARY'"
sudo chmod +x "$BINARY"
info "二进制已安装"

# 创建 systemd 服务
if [ ! -f "$SERVICE_FILE" ]; then
    info "创建 systemd 服务..."
    sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=Nezha Dashboard
After=network.target

[Type]
Type=simple
WorkingDirectory=/opt/nezha/dashboard
ExecStart=/opt/nezha/dashboard/app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    info "systemd 服务已创建"
else
    warn "服务文件已存在"
fi

# 配置
if [ "$HAS_CONFIG" = false ]; then
    echo ""
    warn "首次安装，请编辑配置文件："
    warn "  sudo vim $DASHBOARD_DIR/data/config.yaml"
    echo ""
    warn "配置参考(按需修改):"
    cat << 'CONFIGEOF'
# 最小配置示例:
listen_port: 8008
site_name: "哪吒监控"
language: zh_CN
install_host: "你的IP:8008"
CONFIGEOF
    echo ""
    info "编辑完成后启动服务: sudo systemctl start nezha-dashboard.service"
    info "然后访问 http://你的IP:8008 完成初始化"
else
    info "启动服务..."
    sudo systemctl enable nezha-dashboard.service 2>/dev/null || true
    sudo systemctl start nezha-dashboard.service
    sleep 2
    if systemctl is-active --quiet nezha-dashboard.service; then
        info "服务运行中！"
        echo "  查看状态: sudo systemctl status nezha-dashboard.service"
        echo "  查看日志: sudo journalctl -u nezha-dashboard --no-pager -n 20"
    else
        error "服务启动失败，查看日志:"
        echo "  sudo journalctl -u nezha-dashboard --no-pager -n 30"
    fi
fi
