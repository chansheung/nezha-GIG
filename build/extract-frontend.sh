#!/bin/bash
# =============================================================================
# 从运行中的 Nezha Dashboard 提取自定义前端 (保留 GPU 面板等修改)
#
# 用法:
#   方式1 (推荐): 从同机文件系统直接复制
#     ./extract-frontend.sh --local /opt/nezha/dashboard
#
#   方式2: 从远程 Dashboard HTTP 下载
#     ./extract-frontend.sh http://你的Dashboard地址:8008
#
# 注意: 方式2 使用 wget 镜像下载，可能遗漏 SPA 动态加载的 JS 分块。
#       如有文件系统访问权限，强烈推荐方式1。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/admin-dist"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[*]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

mkdir -p "$OUTPUT_DIR"

if [ "${1:-}" = "--local" ]; then
    # ============================================================
    # 方式1: 从文件系统直接复制 (推荐)
    # ============================================================
    DASHBOARD_DIR="${2:-/opt/nezha/dashboard}"
    SRC_DIR="$DASHBOARD_DIR/admin-dist"

    if [ ! -d "$SRC_DIR" ]; then
        error "目录不存在: $SRC_DIR"
        error "请确认 Dashboard 安装路径 (默认: /opt/nezha/dashboard)"
        exit 1
    fi

    info "从文件系统复制前端: $SRC_DIR → $OUTPUT_DIR"
    cp -r "$SRC_DIR"/. "$OUTPUT_DIR/"

    FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l)
    info "完成！共复制 $FILE_COUNT 个文件"

elif [ -n "${1:-}" ]; then
    # ============================================================
    # 方式2: 从 HTTP 下载 (备选)
    # ============================================================
    DASHBOARD_URL="$1"

    if ! command -v wget >/dev/null 2>&1; then
        error "需要 wget，请先安装: sudo apt-get install wget"
        exit 1
    fi

    info "从 $DASHBOARD_URL HTTP 下载前端 ..."

    # 测试连通性
    if ! curl -sfI "$DASHBOARD_URL/dashboard/" >/dev/null 2>&1; then
        error "无法访问 $DASHBOARD_URL/dashboard/"
        exit 1
    fi

    # 使用 wget 镜像下载 (跟随链接，下载页面依赖资源)
    wget --mirror \
         --no-host-directories \
         --cut-dirs=1 \
         --directory-prefix="$OUTPUT_DIR" \
         --page-requisites \
         --no-parent \
         --quiet \
         --show-progress \
         "$DASHBOARD_URL/dashboard/" || {
        error "wget 下载失败"
        exit 1
    }

    FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l)
    info "HTTP 下载完成！共获取 $FILE_COUNT 个文件"

    if [ "$FILE_COUNT" -lt 5 ]; then
        warn "文件数量偏少 ($FILE_COUNT)，可能遗漏了 SPA 动态加载的 JS 分块"
        warn "强烈建议使用方式1 (文件系统复制):"
        warn "  ./extract-frontend.sh --local /opt/nezha/dashboard"
    fi
else
    echo "用法:"
    echo "  $0 --local /opt/nezha/dashboard    # 从文件系统复制 (推荐)"
    echo "  $0 http://host:8008                 # 从 HTTP 下载 (备选)"
    exit 1
fi

echo ""
info "前端已保存到 $OUTPUT_DIR"
warn "现在运行 build.sh 将自动使用此自定义前端"
