#!/usr/bin/env bash
# =============================================================================
# user-frontend-vram.sh — patch the user-facing dashboard JS bundle
# -----------------------------------------------------------------------------
# 给 user-dist 的主 JS bundle 打两处增量补丁：
#   1. GPU VRAM 面板：从 temperatures 数组里提取 GPU_*_mem_used / _mem_total，
#      在每张 GPU 卡下方多渲染一行「已用 / 总量」显存。
#   2. 温度列表过滤：把 _mem_used / _mem_total 伪温度项从温度列表里剔除
#      （它们是后端为驱动 VRAM 面板而塞进 temperatures 的数据，不应显示给用户）。
#
# 设计要点：
#   * 用 Python 正则做补丁 —— 复杂 JS 字符串操作比 sed 可靠得多。
#   * 锚点全部落在【不会被压缩】的 token 上（属性名 .state.temperatures /
#     className 字符串 / JSX prop 名 / 内置方法 .map .filter .toFixed /
#     字符串字面量 "chart-3" "0 Bytes"），被压缩的局部变量名用捕获组取出后再回填。
#     因 此即使换一个 minify 产物（变量名重命名）也能正确补丁。
#   * 每个锚点应用前断言「恰好匹配 1 次」，不唯一就立即 FAIL —— 上游 bundle
#     一旦结构变化会在构建期立即暴露，而不是静默产出坏 UI。
#   * 输出写到临时文件再原子 mv 回原文件，patcher 任何一步失败都不会破坏原文件。
#   * 幂等：检测到已打补丁则跳过（便于 Docker layer cache / 本地重复运行）。
#
# 用法： user-frontend-vram.sh <path-to-index.HASH.js>
# =============================================================================
set -euo pipefail

JS="${1:-}"
if [ -z "$JS" ]; then
    echo "ERROR: usage: $0 <path-to-user-dist-index.js>" >&2
    exit 2
fi
if [ ! -f "$JS" ]; then
    echo "ERROR: JS bundle not found: $JS" >&2
    exit 2
fi

# --- 已打过补丁则跳过（幂等）---
if grep -qF '__gmU' "$JS"; then
    echo "[user-frontend-vram] already patched, skipping: $JS"
    exit 0
fi

# --- 定位 python3 ---
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required (install with: apt-get install -y python3)" >&2
    exit 3
fi

echo "[user-frontend-vram] patching: $JS ($(wc -c <"$JS") bytes)"

# 临时文件与目标同目录 → mv 原子；trap 兜底清理
TMP="$(mktemp "${JS}.patched.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

# 把 patched bundle 写到 stdout，日志写到 stderr。
# heredoc 用 'PYEOF' 加引号 → 完全阻止 shell 对 $ ` \ 等的展开，原样喂给 python。
python3 - "$JS" >"$TMP" <<'PYEOF'
import re, sys

src = sys.argv[1]
JS = open(src, encoding="utf-8").read()
orig_len = len(JS)

# ---------------------------------------------------------------------------
# 定位「字节 -> 人类可读」格式化函数（例如 function H(n,e=2){if(!+n)return"0 Bytes"...）
# 名字会被压缩，故用稳定的函数体特征捕获它；后续 VRAM 显示行用它格式化显存字节数。
# ---------------------------------------------------------------------------
m = re.search(r'function (\w)\((\w+),e=2\)\{if\(!\+\2\)return"0 Bytes"', JS)
if not m:
    sys.exit("FATAL: byte-formatter (bytes->human) not found — bundle layout changed?")
FMT = m.group(1)

edits = []  # (name, old_escaped, new)

# ---- Edit 1 / VRAM-extract: 在 gpu/host 数组解构后追加显存提取 -------------------
# 锚点（稳定）：.state.gpu / .host.gpu 属性名 + ||[] 模式
# 捕获（可压缩）：gpu 数组名、props 对象名
pat = r'const (\w+)=(\w+)\.state\.gpu\|\|\[\],(\w+)=(\w+)\.host\.gpu\|\|\[\];'
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e1 anchor (gpu/host destructure) not found")
gA, gP = g.group(1), g.group(2)
ins = (f"const __tA={gP}.state.temperatures||[],__gmU=[],__gmT=[];"
       f"for(let __gi=0;__gi<{gA}.length;__gi++){{"
       f"let __uu=__tA.find(__z=>__z.Name===`GPU_${{__gi}}_mem_used`);"
       f"__gmU[__gi]=__uu?__uu.Temperature:0;"
       f"let __tt=__tA.find(__z=>__z.Name===`GPU_${{__gi}}_mem_total`);"
       f"__gmT[__gi]=__tt?__tt.Temperature:0;}}")
edits.append(("e1-vram-extract", re.escape(g.group(0)), g.group(0)+ins))

# ---- Edit 2 / 调用点1（host-gpu 分支）：透传 VRAM props -------------------------
# 锚点（稳定）：gpuStat: / gpuName: / messageHistory: / period: 这些 JSX prop 名
# 捕获（可压缩）：gpu 数组名、下标、gpuName 值变量、messageHistory/period 变量
pat = r'gpuStat:(\w+)\[(\w+)\],gpuName:(\w+),messageHistory:(\w+),period:(\w+)'
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e2 anchor (call-site #1) not found")
gA, gi = g.group(1), g.group(2)
new = (f"gpuStat:{gA}[{gi}],gpuName:{g.group(3)},"
       f"gpuMemUsed:__gmU[{gi}],gpuMemTotal:__gmT[{gi}],"
       f"messageHistory:{g.group(4)},period:{g.group(5)}")
edits.append(("e2-callsite-hostgpu", re.escape(g.group(0)), new))

# ---- Edit 3 / 调用点2（fallback 分支 #N）：透传 VRAM props ----------------------
# 锚点（稳定）：gpuName:`#${...+1}` 模板 + messageHistory/period prop 名
pat = r'gpuName:`#\$\{(\w+)\+1\}`,messageHistory:(\w+),period:(\w+)'
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e3 anchor (call-site #2) not found")
gi = g.group(1)
new = (f"gpuName:`#${{{gi}+1}}`,"
       f"gpuMemUsed:__gmU[{gi}],gpuMemTotal:__gmT[{gi}],"
       f"messageHistory:{g.group(2)},period:{g.group(3)}")
edits.append(("e3-callsite-fallback", re.escape(g.group(0)), new))

# ---- Edit 4 / x0 组件签名：接收 VRAM props ------------------------------------
# 锚点（稳定）：function + 解构 prop 名 id/index/gpuStat/gpuName/messageHistory/period
# 捕获（可压缩）：函数名 + 各 prop 的局部别名
pat = (r'function (\w+)\({id:(\w+),index:(\w+),gpuStat:(\w+),'
       r'gpuName:(\w+),messageHistory:(\w+),period:(\w+)\}\)')
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e4 anchor (x0 signature) not found")
fn = g.group(1)
new = (f"function {fn}({{id:{g.group(2)},index:{g.group(3)},gpuStat:{g.group(4)},"
       f"gpuName:{g.group(5)},gpuMemUsed:__mu,gpuMemTotal:__mt,"
       f"messageHistory:{g.group(6)},period:{g.group(7)}}})")
edits.append(("e4-x0-signature", re.escape(g.group(0)), new))

# ---- Edit 5 / GPU 渲染区：包裹百分比 + 追加显存行 ------------------------------
# 锚点（稳定）：className 字符串 "flex items-center gap-2" / "text-xs text-end w-10
#   font-medium" / "size-3 text-[0px]" / "hsl(var(--chart-3))" + max:100,min:0 + toFixed(2)
# 捕获（可压缩）：jsx 命名空间(默认 a)、utilization 变量、sparkline 组件
# 用 \1 / \2 反向引用保证 jsxs/jsx 同一命名空间、toFixed/value 同一 utilization 变量
pat = (r'(\w+)\.jsxs\("section",\{className:"flex items-center gap-2",children:\['
       r'\1\.jsxs\("p",\{className:"text-xs text-end w-10 font-medium",children:\['
       r'(\w+)\.toFixed\(2\),"%"\]\}\),'
       r'\1\.jsx\((\w+),\{className:"size-3 text-\[0px\]",max:100,min:0,value:\2,'
       r'primaryColor:"hsl\(var\(--chart-3\)\)"\}\)\]\}\)')
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e5 anchor (GPU render section) not found")
a, l, xa = g.group(1), g.group(2), g.group(3)
new = (f'{a}.jsxs("section",{{className:"flex flex-col items-end gap-1",children:['
       f'{a}.jsx("div",{{className:"flex items-center gap-2",children:['
       f'{a}.jsxs("p",{{className:"text-xs text-end w-10 font-medium",children:[{l}.toFixed(2),"%"]}}),'
       f'{a}.jsx({xa},{{className:"size-3 text-[0px]",max:100,min:0,value:{l},primaryColor:"hsl(var(--chart-3))"}})'
       f']}}),'
       f'__mu!==void 0&&__mt!==void 0&&__mt>0&&'
       f'{a}.jsxs("div",{{className:"flex text-[11px] font-medium items-center gap-2",'
       f'children:[{FMT}(__mu*1024*1024)," / ",{FMT}(__mt*1024*1024)]}})'
       f']}})')
edits.append(("e5-vram-display", re.escape(g.group(0)), new))

# ---- Edit 6 / 温度列表过滤 _mem ----------------------------------------------
# 锚点（稳定）：.temperatures.map( + .Name / .includes 方法名
# 捕获（可压缩）：map 回调的 (value, index) 变量名；用捕获到的 value 名构造 filter
pat = r'\.temperatures\.map\(\((\w+),(\w+)\)=>'
g = re.search(pat, JS)
if not g: sys.exit("FATAL: e6 anchor (temperature list .map) not found")
v = g.group(1)
new = f".temperatures.filter({v}=>!{v}.Name.includes(\"_mem\")).map(({v},{g.group(2)})=>"
edits.append(("e6-temp-mem-filter", re.escape(g.group(0)), new))

# ---------------------------------------------------------------------------
# 应用：每个 old 必须恰好出现 1 次，否则 FAIL（结构变了不能静默继续）
# ---------------------------------------------------------------------------
for name, old_esc, new in edits:
    cnt = len(re.findall(old_esc, JS))
    if cnt != 1:
        sys.exit(f"FATAL: {name}: expected exactly 1 match, found {cnt} — "
                 f"upstream bundle changed or already patched")
    JS = re.sub(old_esc, lambda _m, n=new: n, JS, count=1)

# ---------------------------------------------------------------------------
# 后置校验：所有关键 token 必须存在
# ---------------------------------------------------------------------------
must_have = ['__gmU', '__gmT', '__mu', '__mt',
             'gpuMemUsed', 'gpuMemTotal',
             '_mem', 'GPU_${__gi}_mem_used',
             'hsl(var(--chart-3))']
missing = [t for t in must_have if t not in JS]
if missing:
    sys.exit(f"FATAL: post-patch verification failed, missing tokens: {missing}")

sys.stdout.write(JS)
sys.stderr.write(f"[user-frontend-vram] {len(edits)} edits applied, "
                 f"{len(JS)-orig_len:+d} bytes, byte-fmt-fn={FMT}\n")
PYEOF
patcher_rc=$?

if [ "$patcher_rc" -ne 0 ]; then
    echo "ERROR: patcher failed (rc=$patcher_rc), original file untouched: $JS" >&2
    rm -f "$TMP"
    exit "$patcher_rc"
fi

# 原子替换（同目录 → 同文件系统 → rename 原子）
chmod --reference="$JS" "$TMP" 2>/dev/null || chmod 644 "$TMP"
mv -f "$TMP" "$JS"
trap - EXIT

# --- 兜底二次校验（防御深度）---
for tok in '__gmU' 'gpuMemUsed' 'gpuMemTotal' '_mem'; do
    if ! grep -qF "$tok" "$JS"; then
        echo "ERROR: post-patch token check failed for '$tok' in $JS" >&2
        exit 4
    fi
done

echo "[user-frontend-vram] OK — patched ($(wc -c <"$JS") bytes): $JS"
