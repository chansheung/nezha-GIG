# =============================================================================
# CVE-2026-53519 Targeted Security Fix — Nezha Dashboard v2.0.3
# -----------------------------------------------------------------------------
# Clones upstream v2.0.3, applies ONLY the path traversal fix, builds Linux
# amd64. Does NOT upgrade to v2.0.13 — all v2.0.3 behavior is preserved.
#
# Vulnerability: strings.HasPrefix("/dashboard") allows /dashboard.. prefix
#                confusion → path.Join escapes admin-dist → arbitrary file read
# Fix:           trailing slash + os.OpenRoot root-anchored file access
# Reference:     GHSA-5c25-7vpj-9mqh
# =============================================================================

ARG GOLANG_IMAGE=golang:1.26-bookworm
# proxy.golang.org 在本机不可达 —— 默认走国内镜像站，可通过 --build-arg 覆盖
ARG GOPROXY=https://goproxy.cn,direct
# github.com 在本机间歇性不可达 —— 默认经 ghproxy.net 代理访问 (留空=直连)
ARG GITHUB_PROXY=https://ghproxy.net

FROM ${GOLANG_IMAGE} AS builder

# 关键：全局 ARG (FROM 之前声明) 在 build stage 内不可见，
# 必须在此 re-declare，否则下方引用解析为空
ARG GOPROXY
ARG GITHUB_PROXY

ENV DEBIAN_FRONTEND=noninteractive \
    GOPATH=/go \
    PATH="/go/bin:${PATH}" \
    GOPROXY=${GOPROXY} \
    GITHUB_PROXY=${GITHUB_PROXY}

# 本机到 github releases 的 HTTP/2 流极不稳定 (curl: (18) HTTP/2 stream not closed cleanly)，
# 且 github.com / ghproxy 速率波动大 —— 配置 curl 强制 HTTP/1.1、自动重试，
# 并用 speed-based 超时 (仅当持续 60s 低于 1KB/s 才中止)，让慢但稳定的下载能完成
RUN printf -- '--retry 12\n--retry-delay 3\n--retry-connrefused\n--retry-all-errors\n--http1.1\n--connect-timeout 15\n--speed-limit 1024\n--speed-time 60\n' > /root/.curlrc

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip curl ca-certificates gcc libc6-dev python3 \
    && rm -rf /var/lib/apt/lists/*

# 优先使用 host 端预下载的 yq (断点续传，最抗 github 抖动)；缺失则经代理 curl 兜底
COPY vendor/ /tmp/vendor/
RUN set -eu; \
    if [ -s /tmp/vendor/yq ]; then \
        echo "=== using pre-fetched yq from vendor/ ==="; \
        cp /tmp/vendor/yq /usr/local/bin/yq; \
    else \
        RAW="https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64"; \
        URL="${GITHUB_PROXY:+${GITHUB_PROXY}/}${RAW}"; \
        echo "=== fetching yq from $URL ==="; \
        curl -fsSL -o /usr/local/bin/yq "$URL"; \
    fi && chmod +x /usr/local/bin/yq && yq --version

WORKDIR /src

# Clone the USER'S base version (v2.0.3) — NOT v2.0.13
# github.com 在本机间歇性不可达 —— 经 ${GITHUB_PROXY} 透明代理 (git url.insteadOf)，
# 强制 HTTP/1.1，并套重试循环 (最多 12 次)；用 go.mod 作为成功标志 (main.go 不在根目录)
RUN git config --global http.version HTTP/1.1 && \
    git config --global http.lowSpeedLimit 1000 && \
    git config --global http.lowSpeedTime 30 && \
    if [ -n "${GITHUB_PROXY}" ]; then \
        git config --global url."${GITHUB_PROXY}/https://github.com/".insteadOf "https://github.com/"; \
    fi && \
    for i in $(seq 1 12); do \
        rm -rf /src/.git /src/* 2>/dev/null || true; \
        if git clone --depth 1 --branch v2.0.3 https://github.com/nezhahq/nezha.git .; then \
            echo "=== nezha v2.0.3 cloned on attempt $i ==="; break; \
        fi; \
        echo "[$i/12] clone failed, retry in 5s..."; sleep 5; \
    done && test -f go.mod

# Apply ONLY the security fix — replace controller.go with patched version
COPY patches/controller.go cmd/dashboard/controller/controller.go

# Verify the fix is present (fail fast if patch didn't apply)
RUN grep -q 'OpenRoot' cmd/dashboard/controller/controller.go \
    && grep -q '"/dashboard/"' cmd/dashboard/controller/controller.go \
    && ! grep -Eq '^\s*"path"$' cmd/dashboard/controller/controller.go \
    && ! grep -q 'path\.Join' cmd/dashboard/controller/controller.go

# Fetch official frontend dists
# NOTE: To preserve GPU panel customization, see extract-frontend.sh
# 经 ${GITHUB_PROXY} 代理 fetch-frontends.sh 内硬编码的 github.com URL (失败仍优雅降级为占位前端)
RUN if [ -n "${GITHUB_PROXY}" ]; then \
        sed -i "s|https://github.com|${GITHUB_PROXY}/https://github.com|g" script/fetch-frontends.sh; \
    fi && \
    chmod +x script/fetch-frontends.sh \
    && if ./script/fetch-frontends.sh; then \
         echo "=== Frontend dists fetched successfully ==="; \
       else \
         echo "========================================" >&2; \
         echo "WARNING: fetch-frontends.sh failed!" >&2; \
         echo "Dashboard UI will not work without frontend." >&2; \
         echo "========================================" >&2; \
       fi \
    && mkdir -p cmd/dashboard/user-dist cmd/dashboard/admin-dist \
    && ([ -f cmd/dashboard/user-dist/index.html ] \
        || echo "<html><body>frontend placeholder</body></html>" > cmd/dashboard/user-dist/index.html) \
    && ([ -f cmd/dashboard/admin-dist/index.html ] \
        || echo "<html><body>admin placeholder</body></html>" > cmd/dashboard/admin-dist/index.html)

# Apply custom frontend if provided (from extract-frontend.sh)
COPY admin-dist/ /tmp/custom-frontend/
RUN if [ -s /tmp/custom-frontend/index.html ]; then \
      rm -rf cmd/dashboard/admin-dist/*; \
      cp -r /tmp/custom-frontend/. cmd/dashboard/admin-dist/; \
      echo "=== Custom frontend applied (GPU panel preserved) ==="; \
    else \
      echo "=== Using official frontend ==="; \
    fi

# Ensure non-bundled public assets (logo, animated-man, favicons, manifest) are present
# fetch-frontends.sh may miss these files; copy with -n (no-clobber) so upstream-provided versions win
COPY assets/ /tmp/nezha-assets/
RUN cp -rn /tmp/nezha-assets/admin-dist/. cmd/dashboard/admin-dist/ \
    && cp -rn /tmp/nezha-assets/user-dist/. cmd/dashboard/user-dist/ \
    && echo "=== Missing public assets ensured ===" \
    && echo "=== admin-dist assets ===" && ls -la cmd/dashboard/admin-dist/*.svg cmd/dashboard/admin-dist/*.webp 2>/dev/null \
    && echo "=== user-dist assets ===" && ls -la cmd/dashboard/user-dist/*.webp cmd/dashboard/user-dist/*.png cmd/dashboard/user-dist/*.ico cmd/dashboard/user-dist/*.json 2>/dev/null

# Patch user frontend: add GPU VRAM panel + filter _mem entries from the temperature list.
# Runs AFTER user-dist is fully assembled (frontends fetched + public assets ensured).
# python3 (installed above) is required by the patcher. See patches/user-frontend-vram.sh.
# NOTE: vite uses dot-separated hash naming (index.HASH.js), so glob is index*.js not index-*.js.
COPY patches/user-frontend-vram.sh /tmp/user-frontend-vram.sh
RUN chmod +x /tmp/user-frontend-vram.sh \
    && USER_JS="$(ls cmd/dashboard/user-dist/assets/index*.js 2>/dev/null | grep -v '\.css$' | head -1)" \
    && if [ -n "$USER_JS" ]; then \
         /tmp/user-frontend-vram.sh "$USER_JS" \
         && echo "=== User frontend VRAM patch applied to $USER_JS ==="; \
       else \
         echo "WARNING: user-dist main JS (index*.js) not found, skipping VRAM patch"; \
       fi

# Generate Swagger docs using go.mod-pinned swag version
RUN go run github.com/swaggo/swag/cmd/swag init --pd -d cmd/dashboard -g main.go -o cmd/dashboard/docs

RUN mkdir -p /output

# Record source commit for traceability
RUN git rev-parse HEAD > /output/SOURCE_COMMIT

# Build Linux amd64 only (CGO required for SQLite)
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
    go build \
    -ldflags="-s -w -X github.com/nezhahq/nezha/service/singleton.Version=v2.0.3-GIG-secfix" \
    -tags go_json -trimpath \
    -o /output/nezha-dashboard ./cmd/dashboard

# -----------------------------------------------------------------------------
# Export stage
# -----------------------------------------------------------------------------
FROM scratch
COPY --from=builder /output/ /output/
