#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知 - 用户级安装
# 运行方式：普通用户运行，无需 root 权限
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[成功]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${NC} $1"; }

# 禁止 root 运行
if [ "$(id -u)" -eq 0 ]; then
    print_warning "请以普通用户运行此脚本"
    exit 1
fi

USER_HOME="$HOME"
PROJECT_DIR="$USER_HOME/workspace/fail2ban/fail2ban-discord"

print_info "用户: $(whoami)"
print_info "安装路径: $PROJECT_DIR"

# 安装 uv
if ! command -v uv &>/dev/null; then
    print_info "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

# 创建项目
print_info "创建 Python 项目..."
mkdir -p "$PROJECT_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat > "$PROJECT_DIR/pyproject.toml" << 'EOF'
[project]
name = "fail2ban-discord"
version = "1.0.0"
requires-python = ">=3.10"
dependencies = ["requests>=2.32.5"]
EOF

cp "$SCRIPT_DIR/notify/discord_notify.py" "$PROJECT_DIR/discord_notify.py"
chmod +x "$PROJECT_DIR/discord_notify.py"

cd "$PROJECT_DIR"
"$USER_HOME/.local/bin/uv" sync

print_success "用户级安装完成！"
echo ""
print_info "下一步："
echo "  运行系统级安装（需要 sudo）："
echo "  sudo bash install-system.sh"
