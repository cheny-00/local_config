#!/usr/bin/env bash

# =============================================================================
# SSH 安全配置工具集
# =============================================================================
#
# 功能：
#   1. setup_ssh_key - 配置 SSH 公钥
#   2. harden_ssh_config - 加固 SSH 配置
#   3. configure_ssh_security - 完整的 SSH 安全配置流程
#
# 使用方法：
#   # 完整配置流程
#   sudo bash ssh_security.sh
#
#   # 仅配置公钥
#   sudo bash ssh_security.sh setup_key [username]
#
#   # 仅加固 SSH 配置
#   sudo bash ssh_security.sh harden
#
#   # 交互式完整配置
#   sudo bash ssh_security.sh full [username]
#
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# =============================================================================
# 辅助函数
# =============================================================================

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

print_step() {
    echo -e "\n${PURPLE}>>> $1${NC}\n"
}

# 检查是否为 root 用户
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "此脚本需要 root 权限，请使用 sudo 运行"
        exit 1
    fi
}

# 显示使用帮助
show_usage() {
    cat << EOF
${CYAN}SSH 安全配置工具集${NC}

使用方法:
  sudo bash ssh_security.sh [命令] [参数]

命令:
  setup_key [username]    配置 SSH 公钥（默认当前用户）
  harden                  加固 SSH 配置（禁用密码登录等）
  full [username]         完整的 SSH 安全配置流程（默认交互式）
  help                    显示此帮助信息

示例:
  # 为 john 用户配置公钥
  sudo bash ssh_security.sh setup_key john

  # 加固 SSH 配置
  sudo bash ssh_security.sh harden

  # 完整配置流程（交互式）
  sudo bash ssh_security.sh full

  # 为 root 用户完整配置
  sudo bash ssh_security.sh full root

EOF
}

# =============================================================================
# SSH 公钥配置
# =============================================================================

setup_ssh_key() {
    local username="${1:-}"
    local user_home=""
    local interactive=false

    print_step "配置 SSH 公钥"

    # 如果没有提供用户名，交互式询问
    if [ -z "$username" ]; then
        interactive=true
        read -p "请输入用户名 (留空则使用当前用户): " username
        username=${username:-${SUDO_USER:-root}}
    fi

    # 检查用户是否存在
    if ! id "$username" &>/dev/null; then
        print_error "用户 $username 不存在"
        return 1
    fi

    # 获取用户主目录
    if [ "$username" = "root" ]; then
        user_home="/root"
    else
        user_home="/home/$username"
    fi

    print_info "将为用户 $username 配置 SSH 公钥"
    print_info "主目录: $user_home"

    local ssh_dir="$user_home/.ssh"
    local authorized_keys="$ssh_dir/authorized_keys"

    # 创建 .ssh 目录
    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        chown "$username:$username" "$ssh_dir"
        print_success "已创建 $ssh_dir"
    fi

    # 如果是非交互式且没有提供公钥，提示错误
    if [ "$interactive" = false ] && [ -z "${SSH_PUBLIC_KEY:-}" ]; then
        print_error "非交互式模式需要设置 SSH_PUBLIC_KEY 环境变量"
        return 1
    fi

    # 读取公钥
    local ssh_public_key="${SSH_PUBLIC_KEY:-}"
    if [ -z "$ssh_public_key" ]; then
        echo -e "${YELLOW}请输入 SSH 公钥 (粘贴后按回车):${NC}"
        read ssh_public_key
    fi

    # 验证公钥格式
    if [[ ! "$ssh_public_key" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)\ [A-Za-z0-9+/]+[=]{0,3}(\s.*)?$ ]]; then
        print_error "公钥格式无效"
        return 1
    fi

    # 写入 authorized_keys
    if [ ! -f "$authorized_keys" ]; then
        touch "$authorized_keys"
    fi

    # 检查公钥是否已存在
    if grep -qF "$ssh_public_key" "$authorized_keys" 2>/dev/null; then
        print_warning "该公钥已存在，跳过"
    else
        echo "$ssh_public_key" >> "$authorized_keys"
        print_success "公钥已添加到 $authorized_keys"
    fi

    # 设置正确的权限
    chmod 600 "$authorized_keys"
    chown "$username:$username" "$authorized_keys"

    print_success "SSH 公钥配置完成"
    return 0
}

# =============================================================================
# SSH 安全加固
# =============================================================================

harden_ssh_config() {
    print_step "加固 SSH 安全配置"

    local sshd_config="/etc/ssh/sshd_config"
    local backup_file="${sshd_config}.backup.$(date +%Y%m%d_%H%M%S)"

    # 备份原配置
    if [ -f "$sshd_config" ]; then
        cp "$sshd_config" "$backup_file"
        print_info "已备份 SSH 配置到: $backup_file"
    else
        print_error "SSH 配置文件不存在: $sshd_config"
        return 1
    fi

    print_info "正在修改 SSH 配置..."

    # 定义安全配置项
    declare -A ssh_settings=(
        ["PasswordAuthentication"]="no"
        ["PermitRootLogin"]="prohibit-password"
        ["PubkeyAuthentication"]="yes"
        ["PermitEmptyPasswords"]="no"
        ["ChallengeResponseAuthentication"]="no"
        ["UsePAM"]="yes"
        ["X11Forwarding"]="no"
        ["MaxAuthTries"]="3"
        ["MaxSessions"]="10"
    )

    # 应用配置
    for key in "${!ssh_settings[@]}"; do
        value="${ssh_settings[$key]}"

        # 检查配置项是否存在
        if grep -qE "^#?\s*${key}\s+" "$sshd_config"; then
            # 如果存在，替换
            sed -i.tmp "s/^#\?\s*${key}\s\+.*/${key} ${value}/" "$sshd_config"
            print_info "已更新: $key $value"
        else
            # 如果不存在，追加
            echo "${key} ${value}" >> "$sshd_config"
            print_info "已添加: $key $value"
        fi
    done

    # 清理临时文件
    rm -f "${sshd_config}.tmp"

    # 验证配置
    print_info "验证 SSH 配置..."
    if sshd -t -f "$sshd_config" 2>/dev/null; then
        print_success "SSH 配置验证通过"
    else
        print_error "SSH 配置验证失败，正在恢复备份..."
        cp "$backup_file" "$sshd_config"
        return 1
    fi

    # 重启 SSH 服务
    print_info "重启 SSH 服务..."
    if systemctl is-active --quiet sshd; then
        systemctl restart sshd
        print_success "SSH 服务已重启 (sshd)"
    elif systemctl is-active --quiet ssh; then
        systemctl restart ssh
        print_success "SSH 服务已重启 (ssh)"
    else
        print_warning "无法确定 SSH 服务名称，请手动重启"
        print_info "可尝试: systemctl restart sshd 或 systemctl restart ssh"
        return 1
    fi

    print_success "SSH 安全配置已加固"
    print_warning "密码登录已禁用，请确保公钥配置正确！"
    print_info "如需恢复，请使用备份文件: $backup_file"

    return 0
}

# =============================================================================
# 完整的 SSH 安全配置流程
# =============================================================================

configure_ssh_security() {
    local username="${1:-}"

    print_step "SSH 安全配置"

    # 尝试配置 SSH 公钥
    if setup_ssh_key "$username"; then
        # 如果成功配置了公钥，询问是否要加固 SSH
        echo ""
        read -p "是否要禁用密码登录并加固 SSH 配置? (y/n): " harden_choice

        if [[ "$harden_choice" =~ ^[Yy]$ ]]; then
            harden_ssh_config
        else
            print_warning "跳过 SSH 加固配置"
        fi
    else
        print_warning "未配置 SSH 公钥，跳过 SSH 加固"
    fi
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    local command="${1:-full}"
    local arg="${2:-}"

    # 检查 root 权限
    check_root

    case "$command" in
        setup_key)
            setup_ssh_key "$arg"
            ;;
        harden)
            harden_ssh_config
            ;;
        full)
            configure_ssh_security "$arg"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# 只有当脚本被直接执行时才运行 main 函数
# 这样可以让脚本被其他脚本 source 时不自动执行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
