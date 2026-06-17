#!/bin/bash
# =============================================================================
# CVE-2026-53519 Targeted Security Fix Build (Linux amd64 only)
# Applies ONLY the path traversal fix to v2.0.3 source — preserves all
# existing behavior and customizations.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../dist}"
IMAGE_NAME="nezha-secfix-builder"
CONTAINER_NAME="nezha-secfix-extract"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[*]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }
step()  { echo -e "${CYAN}[>]${NC} $1"; }

echo -e "${RED}================================================================${NC}"
echo -e "${RED}  CVE-2026-53519 定向安全修复构建${NC}"
echo -e "${RED}  基于 v2.0.3 + 路径穿越补丁 (仅 Linux amd64)${NC}"
echo -e "${RED}================================================================${NC}"
echo ""

if ! command -v docker >/dev/null 2>&1; then
    error "未检测到 Docker，请先安装"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker daemon 未运行"
    exit 1
fi

FRONTEND_DIR="$SCRIPT_DIR/admin-dist"
if [ -s "$FRONTEND_DIR/index.html" ]; then
    warn "检测到自定义前端 ($FRONTEND_DIR)，构建时将覆盖官方前端"
else
    info "使用官方前端 (如需保留 GPU 面板修改，先运行 ./extract-frontend.sh)"
fi

# Ensure frontend dir always exists for Docker COPY
mkdir -p "$FRONTEND_DIR"

step "构建 Docker 镜像 ..."
# NOTE: --pull 默认关闭 —— 本机无法访问 registry-1.docker.io，需复用本地
#       由镜像站拉取并 tag 的 golang:1.26-bookworm。
#       如 registry 可达，传 PULL_IMAGE=1 强制刷新。
docker build \
    ${PULL_IMAGE:+--pull} \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"

step "提取构建产物 ..."
rm -rf "${OUTPUT_DIR:?}"/*
mkdir -p "$OUTPUT_DIR"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker create --name "$CONTAINER_NAME" "$IMAGE_NAME" >/dev/null
docker cp "$CONTAINER_NAME:/output/." "$OUTPUT_DIR/"
docker rm "$CONTAINER_NAME" >/dev/null

echo ""
info "构建完成！产物："
ls -lh "$OUTPUT_DIR"

echo ""
echo -e "${CYAN}---- 部署 ----${NC}"
echo "  sudo systemctl stop nezha-dashboard.service"
echo "  sudo cp \"$OUTPUT_DIR/nezha-dashboard\" /opt/nezha/dashboard/app"
echo "  sudo systemctl start nezha-dashboard.service"
echo ""
echo -e "${CYAN}---- 验证 ----${NC}"
echo "  curl -i 'http://localhost:8008/dashboard../data/config.yaml'"
echo "  # 应返回 404，而非 200"
