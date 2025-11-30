#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知安装脚本
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

# 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
    print_error "此脚本需要 root 权限"
    exit 1
fi

# 获取实际用户
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER=$(whoami)
fi

print_info "当前用户: $REAL_USER"

# ==============================================================================
# 1. 检查依赖
# ==============================================================================

print_info "检查依赖..."

# 检查 fail2ban
if ! command -v fail2ban-client &>/dev/null; then
    print_error "fail2ban 未安装"
    print_info "请先安装: sudo apt install fail2ban"
    exit 1
fi

# 检查 uv
if ! command -v uv &>/dev/null; then
    print_warning "uv 未安装"
    print_info "正在安装 uv..."
    sudo -u "$REAL_USER" curl -LsSf https://astral.sh/uv/install.sh | sh
fi

print_success "依赖检查完成"

# ==============================================================================
# 2. 创建 Python 项目
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="/home/$REAL_USER/workspace/fail2ban/fail2ban-discord"

print_info "创建项目目录: $PROJECT_DIR"
sudo -u "$REAL_USER" mkdir -p "$PROJECT_DIR"

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
chown "$REAL_USER:$REAL_USER" "$PROJECT_DIR/discord_notify.py"
chown "$REAL_USER:$REAL_USER" "$PROJECT_DIR/pyproject.toml"

# 初始化 uv 环境
print_info "初始化 Python 环境..."
cd "$PROJECT_DIR"
sudo -u "$REAL_USER" /home/$REAL_USER/.local/bin/uv sync

print_success "Python 项目创建完成"

# ==============================================================================
# 3. 安装配置文件
# ==============================================================================

print_info "安装 fail2ban 配置文件..."

# 安装 action
cp "$SCRIPT_DIR/action.d/discord-webhook.conf" /etc/fail2ban/action.d/
print_success "已安装 action: discord-webhook.conf"

# 安装 filters
for filter in "$SCRIPT_DIR"/filter.d/*.conf; do
    if [ -f "$filter" ]; then
        filename=$(basename "$filter")
        cp "$filter" /etc/fail2ban/filter.d/
        print_success "已安装 filter: $filename"
    fi
done

# 创建包装脚本
cat > /usr/local/bin/fail2ban-discord-notify << EOF
#!/bin/bash
# fail2ban Discord notification wrapper using uv
cd $PROJECT_DIR
exec /home/$REAL_USER/.local/bin/uv run discord_notify.py "\$@"
EOF

chmod +x /usr/local/bin/fail2ban-discord-notify
print_success "已创建包装脚本: /usr/local/bin/fail2ban-discord-notify"

# ==============================================================================
# 4. 配置示例
# ==============================================================================

print_info "安装配置示例..."
mkdir -p /etc/fail2ban/examples

for example in "$SCRIPT_DIR"/examples/*.conf; do
    if [ -f "$example" ]; then
        filename=$(basename "$example")
        cp "$example" /etc/fail2ban/examples/
        print_info "已复制示例: $filename -> /etc/fail2ban/examples/"
    fi
done

# ==============================================================================
# 5. 完成
# ==============================================================================

echo ""
print_success "安装完成！"
echo ""
print_warning "下一步操作:"
echo "1. 配置 Discord webhook URL"
echo "   编辑 /etc/fail2ban/examples/*.conf"
echo "   将 YOUR_DISCORD_WEBHOOK_URL 替换为实际的 webhook URL"
echo ""
echo "2. 启用需要的 jail"
echo "   sudo cp /etc/fail2ban/examples/sshd.conf /etc/fail2ban/jail.d/"
echo "   sudo cp /etc/fail2ban/examples/vaultwarden.conf /etc/fail2ban/jail.d/"
echo ""
echo "3. 配置代理（如果需要）"
echo "   sudo tee /etc/fail2ban/discord-proxy.conf << 'EOF'"
echo "   http_proxy = http://127.0.0.1:7890"
echo "   EOF"
echo ""
echo "4. 重启 fail2ban"
echo "   sudo systemctl restart fail2ban"
echo ""
echo "5. 测试通知"
echo "   /usr/local/bin/fail2ban-discord-notify ban \"test\" \"1.2.3.4\" \"3\" \"3600\" \"YOUR_WEBHOOK_URL\""
echo ""
