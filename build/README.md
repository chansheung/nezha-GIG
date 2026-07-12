# Nezha Dashboard 定向安全修复 (CVE-2026-53519)

> **方式**: 在 v2.0.3 源码上仅应用路径穿越补丁，不升级版本
> **产出**: Linux amd64 二进制

## 漏洞原理

`fallbackToFrontend` 中 `strings.HasPrefix(path, "/dashboard")` 缺少末尾 `/`，
导致 `/dashboard../data/config.yaml` 被接受。`path.Join` 将 `../` 正常化后
逃逸出 `admin-dist` 目录，`os.Stat` + `http.ServeFile` 返回任意文件。

未认证攻击者可读取 `data/config.yaml` (JWT密钥) → 伪造管理员 token → 完全接管。

## 修复内容（4处改动）

1. **import**: 删除 `"path"` (不再使用 `path.Join`)
2. **`checkLocalFileOrFs`**: `os.Stat` + `http.ServeFile` → `os.OpenRoot` + `localRoot.Open`
3. **/dashboard 路由**: `HasPrefix("/dashboard")` → `HasPrefix("/dashboard/")`
4. **用户模板路由**: `path.Join` 拼接 → root/path 分离传递

核心是 `os.OpenRoot` (Go 1.24+)：从 OS 内核层面锚定根目录，`../` 无法逃逸。

## 快速开始

```bash
cd build
./build.sh    # 需要 Docker，产出在 ../dist/nezha-dashboard
```

## 保留 GPU 面板（可选）

默认构建使用官方前端，不包含 GPU 显存显示。
如需保留你之前的 GPU 面板修改：

```bash
# 1. 确保旧 Dashboard 正在运行
# 2. 提取自定义前端
./extract-frontend.sh http://你的Dashboard地址:8008

# 3. 重新构建（会自动检测并使用自定义前端）
./build.sh
```

## 前端公共资源补全

`fetch-frontends.sh` 下载的官方前端 dist 可能缺少非打包的公共资源文件（`logo.svg`、
`animated-man.webp`、favicon 图标、`manifest.json`），导致管理面板 Logo 和动画图显示异常。

`assets/` 目录保存了这些文件的正确版本。Dockerfile 构建时会用 `cp -rn`（不覆盖）
将它们补入 `admin-dist/` 和 `user-dist/`，上游已提供的同名文件优先。

如需更新这些资源，替换 `assets/` 下对应文件后重新构建即可。

> 资源来源: [nezhahq/admin-frontend](https://github.com/nezhahq/admin-frontend) 和
> [nezhahq/user-frontend](https://github.com/nezhahq/user-frontend) 的 `public/` 目录 (Apache 2.0)。
> `favicon.ico` 由 `apple-touch-icon.png` 派生生成（上游未提供）。

## 部署

```bash
sudo systemctl stop nezha-dashboard.service
sudo cp dist/nezha-dashboard /opt/nezha/dashboard/app
sudo systemctl start nezha-dashboard.service
```

## 验证

```bash
# 应返回 404，而非 200
curl -i 'http://localhost:8008/dashboard../data/config.yaml'
curl -i 'http://localhost:8008/dashboard%2e%2e/data/config.yaml'
```

## 目录结构

```
build/
├── Dockerfile                 # v2.0.3 + 补丁编译
├── build.sh                   # Linux 构建脚本
├── extract-frontend.sh        # 从旧 Dashboard 提取自定义前端
├── README.md                  # 本文档
├── patches/
│   └── controller.go          # 补丁版 controller.go (v2.0.3 + CVE 修复)
├── assets/                    # 缺失的公共静态资源 (logo/图标/动画)
│   ├── admin-dist/            #   管理面板: logo.svg, animated-man.webp
│   └── user-dist/             #   用户首页: favicons, manifest.json, animated-man.webp
└── admin-dist/                # (可选) extract-frontend.sh 生成
```

## 与之前方案的区别

| 项目 | 旧方案 (已废弃) | 当前方案 |
|------|----------------|----------|
| 来源 | 上游 v2.0.13 | 上游 v2.0.3 + 定向补丁 |
| 功能变化 | 大量新功能/改动 | 零变化，仅修漏洞 |
| GPU 面板 | 丢失 | 可保留 |
| Windows | 支持 | 不需要 (仅 Linux) |

## 临时缓解

重建前可用 Nginx 拦截（见 `dashboard/nginx-security.conf`），但无法替代二进制修复。
