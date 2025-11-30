#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知 - 无需 root 一键安装
#
# 使用方式：
#   bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/install-noroot.sh)
#
# 特点：
#   ✓ 完全不需要 root 权限
#   ✓ 所有文件安装在用户目录
#   ✓ 自动生成 sudo 安装命令
# ==============================================================================

set -e

# GitHub 配置
GITHUB_REPO="cheny-00/local_config"
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/fail2ban"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Fail2ban Discord 通知 - 无需 root 安装         ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

command_exists() { command -v "$1" &>/dev/null; }

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

# 拒绝 root 运行
if [ "$(id -u)" -eq 0 ]; then
    print_error "请不要以 root 运行此脚本"
    print_info "此脚本会安装到用户目录，不需要 root 权限"
    exit 1
fi

USER_HOME="$HOME"
CURRENT_USER=$(whoami)

print_info "当前用户: ${CYAN}$CURRENT_USER${NC}"
print_info "安装目录: ${CYAN}$USER_HOME${NC}"

# ==============================================================================
# 1. 安装 uv
# ==============================================================================

print_step "Step 1: 安装 uv"

if ! command_exists uv; then
    print_info "正在安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
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
dependencies = ["requests>=2.32.5"]
EOF
print_success "创建 pyproject.toml"

# 下载 discord_notify.py
print_info "下载 discord_notify.py..."
download_file "$BASE_URL/notify/discord_notify.py" "$PROJECT_DIR/discord_notify.py"
chmod +x "$PROJECT_DIR/discord_notify.py"
print_success "下载 discord_notify.py"

# 初始化环境
print_info "初始化 Python 环境..."
cd "$PROJECT_DIR"
"$USER_HOME/.local/bin/uv" sync
print_success "Python 环境初始化完成"

# ==============================================================================
# 3. 下载配置文件到用户目录
# ==============================================================================

print_step "Step 3: 下载配置文件"

CONFIG_DIR="$USER_HOME/workspace/fail2ban/configs"
mkdir -p "$CONFIG_DIR"/{action.d,filter.d,examples}

print_info "配置目录: ${CYAN}$CONFIG_DIR${NC}"

# 下载 action.d
print_info "下载 discord-webhook.conf..."
download_file "$BASE_URL/action.d/discord-webhook.conf" "$CONFIG_DIR/action.d/discord-webhook.conf"

# 下载 filter.d
for filter in vaultwarden qbittorrent caddy-s3 seaweedfs-s3; do
    print_info "下载 ${filter}.conf..."
    download_file "$BASE_URL/filter.d/${filter}.conf" "$CONFIG_DIR/filter.d/${filter}.conf"
done

# 下载 examples
for example in sshd vaultwarden qbittorrent caddy-s3 seaweedfs-s3; do
    print_info "下载示例 ${example}.conf..."
    download_file "$BASE_URL/examples/${example}.conf" "$CONFIG_DIR/examples/${example}.conf"
done

print_success "所有配置文件已下载"

# ==============================================================================
# 4. 生成安装脚本
# ==============================================================================

print_step "Step 4: 生成系统安装脚本"

INSTALL_SCRIPT="$CONFIG_DIR/install-to-system.sh"

cat > "$INSTALL_SCRIPT" << EOF
#!/usr/bin/env bash
# 自动生成的系统安装脚本
# 需要 sudo 权限运行

set -e

echo "正在安装 fail2ban 配置文件..."

# 安装 action
sudo cp "$CONFIG_DIR/action.d/discord-webhook.conf" /etc/fail2ban/action.d/
echo "✓ 安装 action: discord-webhook.conf"

# 安装 filters
for filter in "$CONFIG_DIR"/filter.d/*.conf; do
    filename=\$(basename "\$filter")
    sudo cp "\$filter" /etc/fail2ban/filter.d/
    echo "✓ 安装 filter: \$filename"
done

# 安装 examples
sudo mkdir -p /etc/fail2ban/examples
for example in "$CONFIG_DIR"/examples/*.conf; do
    filename=\$(basename "\$example")
    sudo cp "\$example" /etc/fail2ban/examples/
    echo "✓ 安装示例: \$filename"
done

# 创建包装脚本
sudo tee /usr/local/bin/fail2ban-discord-notify > /dev/null << 'WRAPPER_EOF'
#!/bin/bash
cd $PROJECT_DIR
exec $USER_HOME/.local/bin/uv run discord_notify.py "\\\$@"
WRAPPER_EOF

sudo chmod +x /usr/local/bin/fail2ban-discord-notify
echo "✓ 创建包装脚本: /usr/local/bin/fail2ban-discord-notify"

echo ""
echo "系统安装完成！"
echo ""
echo "下一步："
echo "  1. 编辑配置文件，添加 Discord webhook URL"
echo "  2. 复制配置到 /etc/fail2ban/jail.d/"
echo "  3. 重启 fail2ban: sudo systemctl restart fail2ban"
EOF

chmod +x "$INSTALL_SCRIPT"
print_success "生成安装脚本: ${GREEN}$INSTALL_SCRIPT${NC}"

# ==============================================================================
# 5. 完成
# ==============================================================================

print_step "安装完成！"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          ✓ 用户级安装完成！                       ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${CYAN}━━━ 安装信息 ━━━${NC}"
echo ""
echo -e "  ${BLUE}用户环境 (已安装):${NC}"
echo -e "    uv:           ${GREEN}$USER_HOME/.local/bin/uv${NC}"
echo -e "    Python 项目:  ${GREEN}$PROJECT_DIR${NC}"
echo -e "    配置文件:     ${GREEN}$CONFIG_DIR${NC}"
echo ""
echo -e "  ${BLUE}系统配置 (需要 sudo):${NC}"
echo -e "    fail2ban:     ${YELLOW}/etc/fail2ban/${NC} (未安装)"
echo -e "    包装脚本:     ${YELLOW}/usr/local/bin/fail2ban-discord-notify${NC} (未安装)"
echo ""

echo -e "${CYAN}━━━ 下一步操作 ━━━${NC}"
echo ""

echo -e "${YELLOW}方式 1: 自动安装到系统 (推荐)${NC}"
echo ""
echo "  运行生成的脚本（需要 sudo）："
echo -e "    ${GREEN}bash $INSTALL_SCRIPT${NC}"
echo ""

echo -e "${YELLOW}方式 2: 手动安装到系统${NC}"
echo ""
echo "  1. 安装 fail2ban (如果未安装)"
echo -e "     ${GREEN}sudo apt install fail2ban${NC}"
echo ""
echo "  2. 复制配置文件"
echo -e "     ${GREEN}sudo cp $CONFIG_DIR/action.d/* /etc/fail2ban/action.d/${NC}"
echo -e "     ${GREEN}sudo cp $CONFIG_DIR/filter.d/* /etc/fail2ban/filter.d/${NC}"
echo -e "     ${GREEN}sudo cp -r $CONFIG_DIR/examples /etc/fail2ban/${NC}"
echo ""
echo "  3. 创建包装脚本"
echo -e "     ${GREEN}sudo tee /usr/local/bin/fail2ban-discord-notify > /dev/null << 'EOF'
#!/bin/bash
cd $PROJECT_DIR
exec $USER_HOME/.local/bin/uv run discord_notify.py \"\\\$@\"
EOF${NC}"
echo -e "     ${GREEN}sudo chmod +x /usr/local/bin/fail2ban-discord-notify${NC}"
echo ""

echo -e "${CYAN}━━━ 测试通知脚本 (无需 sudo) ━━━${NC}"
echo ""
echo "  直接运行通知脚本："
echo -e "    ${GREEN}$USER_HOME/.local/bin/uv run --directory $PROJECT_DIR discord_notify.py ban \"test\" \"1.2.3.4\" \"3\" \"3600\" \"YOUR_WEBHOOK_URL\"${NC}"
echo ""

echo -e "${CYAN}━━━ 配置示例 ━━━${NC}"
echo ""
echo "  查看示例配置："
echo -e "    ${GREEN}cat $CONFIG_DIR/examples/sshd.conf${NC}"
echo ""
echo "  支持的服务："
echo "    • SSH (sshd.conf)"
echo "    • Vaultwarden (vaultwarden.conf)"
echo "    • qBittorrent (qbittorrent.conf)"
echo "    • Caddy S3 (caddy-s3.conf)"
echo "    • SeaweedFS S3 (seaweedfs-s3.conf)"
echo ""

echo -e "${CYAN}━━━ 文档 ━━━${NC}"
echo ""
echo "  README: https://github.com/$GITHUB_REPO/blob/$GITHUB_BRANCH/fail2ban/README.md"
echo "  GitHub: https://github.com/$GITHUB_REPO/tree/$GITHUB_BRANCH/fail2ban"
echo ""

echo -e "${BLUE}所有文件已安装到用户目录，无需 root 权限！${NC}"
echo -e "${BLUE}当你准备好时，运行系统安装脚本即可完成配置。${NC}"
echo ""
