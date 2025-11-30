#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知 - 系统级安装
# 运行方式：sudo bash install-system.sh
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[成功]${NC} $1"; }
print_error() { echo -e "${RED}[错误]${NC} $1"; }

# 必须 root 运行
if [ "$(id -u)" -ne 0 ]; then
    print_error "此脚本需要 root 权限"
    exit 1
fi

# 获取实际用户
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

if [ "$REAL_USER" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/$REAL_USER"
fi

PROJECT_DIR="$USER_HOME/workspace/fail2ban/fail2ban-discord"

# 检查用户级安装
if [ ! -f "$PROJECT_DIR/discord_notify.py" ]; then
    print_error "未找到用户级安装"
    print_info "请先运行: bash install-user.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "为用户 $REAL_USER 安装系统级配置..."

# 安装配置
cp "$SCRIPT_DIR/action.d/discord-webhook.conf" /etc/fail2ban/action.d/
print_success "已安装 action"

for filter in "$SCRIPT_DIR"/filter.d/*.conf; do
    [ -f "$filter" ] && cp "$filter" /etc/fail2ban/filter.d/
done
print_success "已安装 filters"

# 创建包装脚本
cat > /usr/local/bin/fail2ban-discord-notify << EOF
#!/bin/bash
cd $PROJECT_DIR
exec $USER_HOME/.local/bin/uv run discord_notify.py "\$@"
EOF
chmod +x /usr/local/bin/fail2ban-discord-notify
print_success "已创建包装脚本"

# 安装示例
mkdir -p /etc/fail2ban/examples
for example in "$SCRIPT_DIR"/examples/*.conf; do
    [ -f "$example" ] && cp "$example" /etc/fail2ban/examples/
done
print_success "已安装示例配置"

print_success "系统级安装完成！"
