#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知安装脚本（智能提权版本）
# 使用方式：普通用户运行，需要时自动 sudo
# ==============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查是否以 root 运行（不推荐）
if [ "$(id -u)" -eq 0 ]; then
    print_warning "检测到以 root 用户运行"
    print_warning "建议以普通用户运行，脚本会在需要时自动 sudo"
    read -p "是否继续以 root 运行? (y/n): " root_confirm
    if [ "$root_confirm" != "y" ]; then
        print_info "退出脚本。请以普通用户重新运行。"
        exit 1
    fi
    CURRENT_USER="root"
    USER_HOME="/root"
else
    CURRENT_USER=$(whoami)
    USER_HOME="$HOME"
fi

print_info "当前用户: $CURRENT_USER"
print_info "用户目录: $USER_HOME"

# ==============================================================================
# 1. 检查依赖
# ==============================================================================

print_info "检查依赖..."

# 检查 fail2ban（需要 sudo）
if ! command -v fail2ban-client &>/dev/null; then
    print_error "fail2ban 未安装"
    print_info "正在尝试安装 fail2ban..."

    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y fail2ban
    elif command -v yum &>/dev/null; then
        sudo yum install -y fail2ban
    else
        print_error "无法自动安装，请手动安装: sudo apt install fail2ban"
        exit 1
    fi
fi

# 检查 uv（用户级，不需要 sudo）
if ! command -v uv &>/dev/null; then
    print_warning "uv 未安装"
    print_info "正在安装 uv（安装到用户目录）..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # 刷新 PATH
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

print_success "依赖检查完成"

# ==============================================================================
# 2. 创建 Python 项目（用户级，不需要 sudo）
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$USER_HOME/workspace/fail2ban/fail2ban-discord"

print_info "创建项目目录: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# 创建 pyproject.toml
cat > "$PROJECT_DIR/pyproject.toml" << 'EOF'
[project]
name = "fail2ban-discord"
version = "1.0.0"
description = "Fail2ban Discord webhook notification with IP geolocation"
requires-python = ">=3.10"
dependencies = [
    "requests>=2.32.5",
]
EOF

# 复制 discord_notify.py
cp "$SCRIPT_DIR/notify/discord_notify.py" "$PROJECT_DIR/discord_notify.py"
chmod +x "$PROJECT_DIR/discord_notify.py"

# 初始化 uv 环境
print_info "初始化 Python 环境..."
cd "$PROJECT_DIR"
"$USER_HOME/.local/bin/uv" sync

print_success "Python 项目创建完成"

# ==============================================================================
# 3. 安装配置文件（需要 sudo）
# ==============================================================================

print_info "安装 fail2ban 配置文件（需要 sudo 权限）..."

# 安装 action
sudo cp "$SCRIPT_DIR/action.d/discord-webhook.conf" /etc/fail2ban/action.d/
print_success "已安装 action: discord-webhook.conf"

# 安装 filters
for filter in "$SCRIPT_DIR"/filter.d/*.conf; do
    if [ -f "$filter" ]; then
        filename=$(basename "$filter")
        sudo cp "$filter" /etc/fail2ban/filter.d/
        print_success "已安装 filter: $filename"
    fi
done

# 创建包装脚本（需要 sudo）
print_info "创建包装脚本（需要 sudo 权限）..."
sudo tee /usr/local/bin/fail2ban-discord-notify > /dev/null << EOF
#!/bin/bash
# fail2ban Discord notification wrapper using uv
cd $PROJECT_DIR
exec $USER_HOME/.local/bin/uv run discord_notify.py "\$@"
EOF

sudo chmod +x /usr/local/bin/fail2ban-discord-notify
print_success "已创建包装脚本: /usr/local/bin/fail2ban-discord-notify"

# ==============================================================================
# 4. 配置示例
# ==============================================================================

print_info "安装配置示例..."
sudo mkdir -p /etc/fail2ban/examples

for example in "$SCRIPT_DIR"/examples/*.conf; do
    if [ -f "$example" ]; then
        filename=$(basename "$example")
        sudo cp "$example" /etc/fail2ban/examples/
        print_info "已复制示例: $filename -> /etc/fail2ban/examples/"
    fi
done

# ==============================================================================
# 5. 完成
# ==============================================================================

echo ""
print_success "安装完成！"
echo ""
print_info "安装路径："
echo "  用户环境: $PROJECT_DIR"
echo "  uv 路径: $USER_HOME/.local/bin/uv"
echo "  系统配置: /etc/fail2ban/"
echo "  包装脚本: /usr/local/bin/fail2ban-discord-notify"
echo ""
print_warning "下一步操作:"
echo "1. 配置 Discord webhook URL"
echo "   编辑 /etc/fail2ban/examples/*.conf"
echo "   将 YOUR_DISCORD_WEBHOOK_URL 替换为实际的 webhook URL"
echo ""
echo "2. 启用需要的 jail"
echo "   sudo cp /etc/fail2ban/examples/sshd.conf /etc/fail2ban/jail.d/"
echo ""
echo "3. 重启 fail2ban"
echo "   sudo systemctl restart fail2ban"
echo ""
echo "4. 测试通知"
echo "   /usr/local/bin/fail2ban-discord-notify ban \"test\" \"1.2.3.4\" \"3\" \"3600\" \"YOUR_WEBHOOK_URL\""
echo ""
