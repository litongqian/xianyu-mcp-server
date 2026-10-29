#!/usr/bin/env bash
# ============================================================
# 闲鱼 MCP 连接器一键安装脚本
# 基于 DoLovya/xianyu-mcp-server (pyxianyu)
#
# 用法:
#   ./install.sh                 # 安装依赖并打印 WorkBuddy 配置
#   ./install.sh --write-config  # 安装并自动写入 ~/.workbuddy/mcp.json
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; }

# 进入脚本所在目录（即仓库根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "🐟 闲鱼 MCP 连接器安装程序"
echo "=========================="
echo ""

# ---------- 1. 环境检查 ----------
if ! command -v python3 &>/dev/null; then
    err "未找到 python3，请先安装 Python 3.11 或更高版本"
    exit 1
fi

PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_OK=$(python3 -c 'import sys; print(1 if sys.version_info >= (3, 11) else 0)')
if [ "$PY_OK" != "1" ]; then
    err "Python 版本过低（当前 $PY_VERSION），需要 >= 3.11"
    exit 1
fi
info "Python $PY_VERSION 检测通过"

if [ ! -d "third_party/pyxianyu" ] || [ -z "$(ls -A third_party/pyxianyu 2>/dev/null)" ]; then
    warn "子模块 third_party/pyxianyu 为空，尝试初始化..."
    git submodule update --init --recursive
fi
info "pyxianyu 子模块就绪"

# ---------- 2. 创建虚拟环境并安装依赖 ----------
if [ ! -d ".venv" ]; then
    info "创建虚拟环境 .venv ..."
    python3 -m venv .venv
fi

PIP=".venv/bin/pip"
info "安装 pyxianyu（核心协议库）..."
"$PIP" install --quiet --upgrade pip
"$PIP" install --quiet -e third_party/pyxianyu
info "安装 xianyu-mcp-server 主包..."
"$PIP" install --quiet -e .
info "依赖安装完成"

# ---------- 3. 初始化 .env ----------
if [ ! -f ".env" ]; then
    cp .env.example .env
    info "已从模板创建 .env（Cookie 留空，可用扫码登录）"
else
    info "已存在 .env，跳过"
fi

# ---------- 4. 冒烟测试 ----------
info "冒烟测试：启动 MCP 服务器并握手..."
if .venv/bin/python - <<'EOF' 2>/dev/null
import subprocess, json, sys
p = subprocess.Popen([sys.executable, "-m", "xianyu_mcp.server"],
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
req = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "initialize",
                  "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                             "clientInfo": {"name": "install-test", "version": "1.0"}}})
out, _ = p.communicate((req + "\n").encode(), timeout=30)
assert b'"serverInfo"' in out, "握手失败"
EOF
then
    info "MCP 服务器握手成功，共 20 个工具可用"
else
    err "冒烟测试失败，请检查上方安装日志"
    exit 1
fi

# ---------- 5. 生成/写入 WorkBuddy MCP 配置 ----------
VENV_PY="$SCRIPT_DIR/.venv/bin/python"
CONFIG=$(cat <<EOF
{
  "mcpServers": {
    "xianyu": {
      "command": "$VENV_PY",
      "args": ["-m", "xianyu_mcp.server"],
      "cwd": "$SCRIPT_DIR",
      "env": {}
    }
  }
}
EOF
)

echo ""
echo "=========================="
info "安装完成！WorkBuddy 配置如下："
echo ""
echo "$CONFIG"
echo ""

MCP_JSON="$HOME/.workbuddy/mcp.json"
if [ "${1:-}" = "--write-config" ]; then
    if [ -f "$MCP_JSON" ]; then
        if grep -q '"xianyu"' "$MCP_JSON"; then
            warn "$MCP_JSON 中已存在 xianyu 配置，跳过写入（如需更新请手动编辑）"
        else
            warn "检测到已有 $MCP_JSON，将手动合并 xianyu 条目..."
            python3 - "$MCP_JSON" "$VENV_PY" "$SCRIPT_DIR" <<'EOF'
import json, sys
path, venv_py, cwd = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("mcpServers", {})["xianyu"] = {
    "command": venv_py, "args": ["-m", "xianyu_mcp.server"],
    "cwd": cwd, "env": {}
}
with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
print("已合并写入 xianyu 服务器配置")
EOF
            info "已写入 $MCP_JSON"
        fi
    else
        mkdir -p "$(dirname "$MCP_JSON")"
        echo "$CONFIG" > "$MCP_JSON"
        info "已创建并写入 $MCP_JSON"
    fi
    echo ""
    warn "最后一步：打开 WorkBuddy 连接器管理页 → 自定义连接器，"
    warn "对新出现的 xianyu 服务器点击「信任」以激活。"
else
    echo "如需自动写入 ~/.workbuddy/mcp.json，请运行:"
    echo "  ./install.sh --write-config"
    echo ""
    echo "或在 WorkBuddy 中手动添加: 连接器管理 → 右上角「自定义连接器」→ 粘贴上方 JSON"
fi

echo ""
echo "下一步：登录闲鱼"
echo "  方式一（推荐）：对 WorkBuddy 说「生成闲鱼登录二维码」，用闲鱼 App 扫码"
echo "  方式二：把 goofish.com 浏览器端的完整 Cookie 粘贴到 .env 的 XIANYU_COOKIE="
echo ""
