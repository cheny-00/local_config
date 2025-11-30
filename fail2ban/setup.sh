#!/usr/bin/env bash

# ==============================================================================
# Fail2ban Discord 通知一键配置脚本
# 使用方式：bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/setup.sh)
# ==============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_title() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Fail2ban Discord 通知一键配置脚本  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
    print_error "此脚本需要 root 权限"
    exit 1
fi

print_title

# ==============================================================================
# 1. 检查依赖
# ==============================================================================

print_info "检查依赖..."

if ! command -v fail2ban-client &>/dev/null; then
    print_error "fail2ban 未安装"
    print_info "请先安装: sudo apt install fail2ban"
    exit 1
fi

if ! [ -f /usr/local/bin/fail2ban-discord-notify ]; then
    print_error "fail2ban-discord-notify 未安装"
    print_info "请先运行安装脚本："
    echo "  bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/install.sh)"
    exit 1
fi

print_success "依赖检查完成"
echo ""

# ==============================================================================
# 2. 获取 Discord Webhook URL
# ==============================================================================

print_info "请输入 Discord Webhook URL"
echo -e "${YELLOW}获取方式：${NC}"
echo "  1. 打开 Discord 服务器设置"
echo "  2. 集成 → Webhook → 新建 Webhook"
echo "  3. 复制 Webhook URL"
echo ""

if [ -t 0 ]; then
    read -p "Discord Webhook URL: " WEBHOOK_URL
else
    print_error "非交互模式需要通过环境变量 WEBHOOK_URL 传入"
    exit 1
fi

if [ -z "$WEBHOOK_URL" ]; then
    print_error "Webhook URL 不能为空"
    exit 1
fi

if [[ ! "$WEBHOOK_URL" =~ ^https://discord\.com/api/webhooks/ ]]; then
    print_warning "Webhook URL 格式可能不正确"
    read -p "是否继续? (y/n): " continue_choice
    if [ "$continue_choice" != "y" ]; then
        exit 1
    fi
fi

print_success "Webhook URL 已设置"
echo ""

# ==============================================================================
# 3. 选择要保护的服务
# ==============================================================================

print_info "请选择要保护的服务（多选，用空格分隔）"
echo "  1) SSH"
echo "  2) Vaultwarden (Bitwarden)"
echo "  3) qBittorrent"
echo ""
read -p "输入选项 (例如: 1 3): " SERVICE_CHOICES

ENABLE_SSH=false
ENABLE_VAULTWARDEN=false
ENABLE_QBITTORRENT=false

for choice in $SERVICE_CHOICES; do
    case $choice in
        1) ENABLE_SSH=true ;;
        2) ENABLE_VAULTWARDEN=true ;;
        3) ENABLE_QBITTORRENT=true ;;
        *) print_warning "未知选项: $choice" ;;
    esac
done

echo ""

# ==============================================================================
# 4. 配置 SSH
# ==============================================================================

if [ "$ENABLE_SSH" = true ]; then
    print_info "配置 SSH 保护..."

    # 使用默认值
    SSH_MAXRETRY=5
    SSH_BANTIME=3600
    SSH_FINDTIME=600

    cat > /etc/fail2ban/jail.d/sshd.conf << EOF
# SSH 保护配置
# 由 fail2ban setup.sh 自动生成

[sshd]
enabled = true
port = ssh,22
filter = sshd
action = iptables-allports[name=sshd]
         discord-webhook[webhook_url="$WEBHOOK_URL"]
logpath = /var/log/auth.log
maxretry = $SSH_MAXRETRY
bantime = $SSH_BANTIME
findtime = $SSH_FINDTIME
EOF

    print_success "SSH 保护已配置 (失败${SSH_MAXRETRY}次封禁${SSH_BANTIME}秒)"
fi

# ==============================================================================
# 5. 配置 Vaultwarden
# ==============================================================================

if [ "$ENABLE_VAULTWARDEN" = true ]; then
    print_info "配置 Vaultwarden 保护..."

    read -p "Vaultwarden 日志路径 (默认: /var/log/vaultwarden.log): " VW_LOGPATH
    VW_LOGPATH=${VW_LOGPATH:-/var/log/vaultwarden.log}

    read -p "Vaultwarden 端口 (默认: 80,443): " VW_PORT
    VW_PORT=${VW_PORT:-80,443}

    VW_MAXRETRY=3
    VW_BANTIME=14400
    VW_FINDTIME=14400

    cat > /etc/fail2ban/jail.d/vaultwarden.conf << EOF
# Vaultwarden (Bitwarden) 保护配置
# 由 fail2ban setup.sh 自动生成

[vaultwarden]
enabled = true
port = $VW_PORT
filter = vaultwarden
action = iptables-allports[name=vaultwarden]
         discord-webhook[webhook_url="$WEBHOOK_URL"]
logpath = $VW_LOGPATH
maxretry = $VW_MAXRETRY
bantime = $VW_BANTIME
findtime = $VW_FINDTIME
EOF

    print_success "Vaultwarden 保护已配置 (失败${VW_MAXRETRY}次封禁${VW_BANTIME}秒)"
fi

# ==============================================================================
# 6. 配置 qBittorrent
# ==============================================================================

if [ "$ENABLE_QBITTORRENT" = true ]; then
    print_info "配置 qBittorrent 保护..."

    read -p "qBittorrent 日志路径 (默认: /var/log/qbittorrent.log): " QB_LOGPATH
    QB_LOGPATH=${QB_LOGPATH:-/var/log/qbittorrent.log}

    read -p "qBittorrent 端口 (默认: 8080): " QB_PORT
    QB_PORT=${QB_PORT:-8080}

    QB_MAXRETRY=3
    QB_BANTIME=7200
    QB_FINDTIME=3600

    cat > /etc/fail2ban/jail.d/qbittorrent.conf << EOF
# qBittorrent WebUI 保护配置
# 由 fail2ban setup.sh 自动生成

[qbittorrent]
enabled = true
port = $QB_PORT
filter = qbittorrent
action = iptables-allports[name=qbittorrent]
         discord-webhook[webhook_url="$WEBHOOK_URL"]
logpath = $QB_LOGPATH
maxretry = $QB_MAXRETRY
bantime = $QB_BANTIME
findtime = $QB_FINDTIME
EOF

    print_success "qBittorrent 保护已配置 (失败${QB_MAXRETRY}次封禁${QB_BANTIME}秒)"
fi

# ==============================================================================
# 7. 代理配置（可选）
# ==============================================================================

echo ""
read -p "是否需要配置代理访问 Discord? (y/n): " SETUP_PROXY

if [ "$SETUP_PROXY" = "y" ]; then
    read -p "代理地址 (例如: http://127.0.0.1:7890): " PROXY_URL

    if [ -n "$PROXY_URL" ]; then
        cat > /etc/fail2ban/discord-proxy.conf << EOF
# Discord webhook 代理配置
# 由 fail2ban setup.sh 自动生成
http_proxy = $PROXY_URL
EOF
        print_success "代理已配置: $PROXY_URL"
    fi
else
    # 如果不需要代理，删除可能存在的代理配置
    if [ -f /etc/fail2ban/discord-proxy.conf ]; then
        rm /etc/fail2ban/discord-proxy.conf
        print_info "已删除旧的代理配置"
    fi
fi

# ==============================================================================
# 8. 重启 fail2ban
# ==============================================================================

echo ""
print_info "重启 fail2ban 服务..."
systemctl restart fail2ban

# 等待服务启动
sleep 2

print_success "fail2ban 已重启"
echo ""

# ==============================================================================
# 9. 显示状态
# ==============================================================================

print_info "当前 fail2ban 状态："
fail2ban-client status

echo ""
print_success "配置完成！"
echo ""

print_warning "下一步操作："
echo "1. 查看特定 jail 状态："

if [ "$ENABLE_SSH" = true ]; then
    echo "   sudo fail2ban-client status sshd"
fi
if [ "$ENABLE_VAULTWARDEN" = true ]; then
    echo "   sudo fail2ban-client status vaultwarden"
fi
if [ "$ENABLE_QBITTORRENT" = true ]; then
    echo "   sudo fail2ban-client status qbittorrent"
fi

echo ""
echo "2. 测试 Discord 通知："
echo "   /usr/local/bin/fail2ban-discord-notify ban \"test-jail\" \"1.2.3.4\" \"3\" \"3600\" \"$WEBHOOK_URL\""
echo ""
echo "3. 查看日志："
echo "   sudo tail -f /var/log/fail2ban.log"
echo ""
echo "4. 调整配置："
echo "   编辑 /etc/fail2ban/jail.d/*.conf"
echo "   修改后执行: sudo fail2ban-client reload"
echo ""
