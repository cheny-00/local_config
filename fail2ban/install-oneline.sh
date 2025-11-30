#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知 - 一键安装脚本
#
# 使用方式：
#   bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/install-oneline.sh)
#
# 或者本地运行：
#   bash install-oneline.sh
# ==============================================================================

set -e

# GitHub 仓库配置
GITHUB_REPO="cheny-00/local_config"
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/fail2ban"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║     Fail2ban Discord 通知 - 一键安装脚本         ║"
    echo "║                                                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &>/dev/null
}

# 下载文件
download_file() {
    local url="$1"
    local dest="$2"

    if command_exists curl; then
        curl -fsSL "$url" -o "$dest"
    elif command_exists wget; then
        wget -q "$url" -O "$dest"
    else
        print_error "需要 curl 或 wget"
        exit 1
    fi
}

print_banner

# ==============================================================================
# 0. 预检查
# ==============================================================================

print_step "Step 0: 环境检查"

# 检查是否以 root 运行
if [ "$(id -u)" -eq 0 ]; then
    print_warning "检测到以 root 用户运行"
    print_info "建议以普通用户运行，脚本会在需要时自动 sudo"
    read -p "是否继续以 root 运行? (y/n): " root_confirm
    if [ "$root_confirm" != "y" ]; then
        print_info "退出脚本。请以普通用户重新运行："
        echo "  bash <(curl -fsSL https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/fail2ban/install-oneline.sh)"
        exit 1
    fi
    CURRENT_USER="root"
    USER_HOME="/root"
else
    CURRENT_USER=$(whoami)
    USER_HOME="$HOME"
fi

print_info "当前用户: ${CYAN}$CURRENT_USER${NC}"
print_info "用户目录: ${CYAN}$USER_HOME${NC}"

# 检查网络连接
print_info "检查网络连接..."
if ! curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com &>/dev/null; then
    print_error "无法连接到 GitHub，请检查网络"
    exit 1
fi
print_success "网络连接正常"

# ==============================================================================
# 1. 安装依赖
# ==============================================================================

print_step "Step 1: 安装依赖"

# 检查并安装 fail2ban
if ! command_exists fail2ban-client; then
    print_warning "fail2ban 未安装，正在尝试安装..."

    if command_exists apt; then
        print_info "使用 apt 安装 fail2ban..."
        sudo apt update && sudo apt install -y fail2ban
    elif command_exists yum; then
        print_info "使用 yum 安装 fail2ban..."
        sudo yum install -y fail2ban
    elif command_exists dnf; then
        print_info "使用 dnf 安装 fail2ban..."
        sudo dnf install -y fail2ban
    else
        print_error "无法自动安装 fail2ban"
        print_info "请手动安装后重新运行此脚本"
        exit 1
    fi

    print_success "fail2ban 安装完成"
else
    print_success "fail2ban 已安装"
fi

# 检查并安装 uv
if ! command_exists uv; then
    print_info "安装 uv (Python 包管理器)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # 刷新 PATH
    export PATH="$USER_HOME/.local/bin:$PATH"
    print_success "uv 安装完成"
else
    print_success "uv 已安装"
fi

# ==============================================================================
# 2. 创建 Python 项目
# ==============================================================================

print_step "Step 2: 创建 Python 项目"

PROJECT_DIR="$USER_HOME/workspace/fail2ban/fail2ban-discord"
print_info "项目目录: ${CYAN}$PROJECT_DIR${NC}"

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
print_success "创建 pyproject.toml"

# 下载 discord_notify.py
print_info "下载 discord_notify.py..."
download_file "$BASE_URL/notify/discord_notify.py" "$PROJECT_DIR/discord_notify.py"
chmod +x "$PROJECT_DIR/discord_notify.py"
print_success "下载 discord_notify.py"

# 初始化 uv 环境
print_info "初始化 Python 虚拟环境..."
cd "$PROJECT_DIR"
"$USER_HOME/.local/bin/uv" sync
print_success "Python 环境初始化完成"

# ==============================================================================
# 3. 下载配置文件
# ==============================================================================

print_step "Step 3: 下载配置文件"

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

print_info "临时目录: $TEMP_DIR"

# 下载 action.d
mkdir -p "$TEMP_DIR/action.d"
print_info "下载 discord-webhook.conf..."
download_file "$BASE_URL/action.d/discord-webhook.conf" "$TEMP_DIR/action.d/discord-webhook.conf"

# 下载 filter.d
mkdir -p "$TEMP_DIR/filter.d"
for filter in vaultwarden qbittorrent caddy-s3 seaweedfs-s3; do
    print_info "下载 ${filter}.conf..."
    download_file "$BASE_URL/filter.d/${filter}.conf" "$TEMP_DIR/filter.d/${filter}.conf"
done

# 下载 examples
mkdir -p "$TEMP_DIR/examples"
for example in sshd vaultwarden qbittorrent caddy-s3 seaweedfs-s3; do
    print_info "下载示例 ${example}.conf..."
    download_file "$BASE_URL/examples/${example}.conf" "$TEMP_DIR/examples/${example}.conf"
done

print_success "所有配置文件下载完成"

# ==============================================================================
# 4. 安装配置文件（需要 sudo）
# ==============================================================================

print_step "Step 4: 安装配置文件"

print_info "安装 fail2ban 配置（需要 sudo 权限）..."

# 安装 action
sudo cp "$TEMP_DIR/action.d/discord-webhook.conf" /etc/fail2ban/action.d/
print_success "安装 action: discord-webhook.conf"

# 安装 filters
for filter in "$TEMP_DIR"/filter.d/*.conf; do
    filename=$(basename "$filter")
    sudo cp "$filter" /etc/fail2ban/filter.d/
    print_success "安装 filter: $filename"
done

# 安装 examples
sudo mkdir -p /etc/fail2ban/examples
for example in "$TEMP_DIR"/examples/*.conf; do
    filename=$(basename "$example")
    sudo cp "$example" /etc/fail2ban/examples/
    print_success "安装示例: $filename"
done

# ==============================================================================
# 5. 创建包装脚本
# ==============================================================================

print_step "Step 5: 创建包装脚本"

print_info "创建 fail2ban-discord-notify..."

sudo tee /usr/local/bin/fail2ban-discord-notify > /dev/null << EOF
#!/bin/bash
# fail2ban Discord notification wrapper using uv
# Auto-generated by install-oneline.sh

cd $PROJECT_DIR
exec $USER_HOME/.local/bin/uv run discord_notify.py "\$@"
EOF

sudo chmod +x /usr/local/bin/fail2ban-discord-notify
print_success "包装脚本创建完成: /usr/local/bin/fail2ban-discord-notify"

# ==============================================================================
# 6. 验证安装
# ==============================================================================

print_step "Step 6: 验证安装"

print_info "测试包装脚本..."
if /usr/local/bin/fail2ban-discord-notify 2>&1 | grep -q "Usage:"; then
    print_success "包装脚本工作正常"
else
    print_warning "包装脚本可能有问题，但已安装"
fi

print_info "检查 fail2ban 配置..."
if sudo fail2ban-client -t &>/dev/null; then
    print_success "fail2ban 配置语法正确"
else
    print_warning "fail2ban 配置可能有问题"
fi

# ==============================================================================
# 7. 完成
# ==============================================================================

print_step "安装完成！"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║              ✓ 安装成功完成！                     ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${CYAN}━━━ 安装信息 ━━━${NC}"
echo ""
echo -e "  ${BLUE}用户环境:${NC}"
echo -e "    uv:        ${GREEN}$USER_HOME/.local/bin/uv${NC}"
echo -e "    Python:    ${GREEN}$PROJECT_DIR${NC}"
echo ""
echo -e "  ${BLUE}系统配置:${NC}"
echo -e "    fail2ban:  ${GREEN}/etc/fail2ban/${NC}"
echo -e "    包装脚本:  ${GREEN}/usr/local/bin/fail2ban-discord-notify${NC}"
echo -e "    示例配置:  ${GREEN}/etc/fail2ban/examples/${NC}"
echo ""

echo -e "${CYAN}━━━ 下一步操作 ━━━${NC}"
echo ""
echo -e "${YELLOW}1. 获取 Discord Webhook URL${NC}"
echo "   • 打开 Discord 服务器设置"
echo "   • 集成 → Webhook → 新建 Webhook"
echo "   • 复制 Webhook URL"
echo ""

echo -e "${YELLOW}2. 配置 SSH 保护（推荐）${NC}"
echo "   复制并运行："
echo ""
echo -e "${GREEN}   sudo tee /etc/fail2ban/jail.d/sshd.conf > /dev/null << 'SSHD_EOF'
[sshd]
enabled = true
port = ssh,22
filter = sshd
action = iptables-allports[name=sshd]
         discord-webhook[webhook_url=\"YOUR_DISCORD_WEBHOOK_URL\"]
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
SSHD_EOF${NC}"
echo ""
echo "   ${BLUE}注意：${NC}替换 YOUR_DISCORD_WEBHOOK_URL 为你的实际 webhook URL"
echo ""

echo -e "${YELLOW}3. 重启 fail2ban${NC}"
echo -e "   ${GREEN}sudo systemctl restart fail2ban${NC}"
echo ""

echo -e "${YELLOW}4. 查看状态${NC}"
echo -e "   ${GREEN}sudo fail2ban-client status sshd${NC}"
echo ""

echo -e "${YELLOW}5. 测试通知${NC}"
echo -e "   ${GREEN}/usr/local/bin/fail2ban-discord-notify ban \"test-jail\" \"1.2.3.4\" \"3\" \"3600\" \"YOUR_WEBHOOK_URL\"${NC}"
echo ""

echo -e "${CYAN}━━━ 更多服务 ━━━${NC}"
echo ""
echo "  查看所有示例配置："
echo -e "    ${GREEN}ls -la /etc/fail2ban/examples/${NC}"
echo ""
echo "  支持的服务："
echo "    • SSH (sshd.conf)"
echo "    • Vaultwarden (vaultwarden.conf)"
echo "    • qBittorrent (qbittorrent.conf)"
echo "    • Caddy S3 (caddy-s3.conf)"
echo "    • SeaweedFS S3 (seaweedfs-s3.conf)"
echo ""

echo -e "${CYAN}━━━ 文档链接 ━━━${NC}"
echo ""
echo "  GitHub: https://github.com/$GITHUB_REPO/tree/$GITHUB_BRANCH/fail2ban"
echo "  README: https://github.com/$GITHUB_REPO/blob/$GITHUB_BRANCH/fail2ban/README.md"
echo ""

echo -e "${BLUE}感谢使用 Fail2ban Discord 通知系统！${NC}"
echo ""
