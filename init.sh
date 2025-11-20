#!/usr/bin/env bash

# =============================================================================
# Dotfiles 一键安装脚本
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

# 全局变量
USERNAME=""
USER_HOME=""
REPO_URL="https://raw.githubusercontent.com/cheny-00/local_config/main"

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

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "无法检测操作系统"
        exit 1
    fi

    print_info "检测到操作系统: $OS $OS_VERSION"
}

# =============================================================================
# 用户管理
# =============================================================================

# 检查用户是否存在
check_user_exists() {
    local user=$1
    id "$user" &>/dev/null
}

# 创建用户
create_user() {
    local user=$1

    print_info "正在创建用户: $user"

    # 创建用户并设置 zsh 为默认 shell
    useradd -m -s /bin/zsh "$user" 2>/dev/null || {
        print_warning "用户可能已存在或 zsh 未安装，稍后设置 shell"
        useradd -m "$user" 2>/dev/null || true
    }

    # 生成随机密码
    local password=$(openssl rand -base64 12)
    echo "$user:$password" | chpasswd

    print_success "用户创建成功！"
    print_info "用户名: $user"
    print_info "密码: $password"

    # 添加 sudo 权限（免密）
    echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
    chmod 440 /etc/sudoers.d/$user

    print_success "已为用户 $user 添加 sudo 权限"
}

# 设置用户
setup_user() {
    # 如果提供了参数，使用参数作为用户名
    if [ -n "$1" ]; then
        USERNAME="$1"
    else
        # 否则交互式询问
        read -p "请输入用户名 (留空则使用 root): " USERNAME
        USERNAME=${USERNAME:-root}
    fi

    # 检查用户是否存在
    if ! check_user_exists "$USERNAME"; then
        print_warning "用户 $USERNAME 不存在"
        read -p "是否创建该用户? (y/n): " create_choice

        if [[ "$create_choice" =~ ^[Yy]$ ]]; then
            create_user "$USERNAME"
        else
            print_error "用户不存在，退出"
            exit 1
        fi
    else
        print_success "用户 $USERNAME 已存在"
    fi

    # 设置用户主目录
    if [ "$USERNAME" = "root" ]; then
        USER_HOME="/root"
    else
        USER_HOME="/home/$USERNAME"
    fi

    print_info "将为用户 $USERNAME 配置 dotfiles"
    print_info "主目录: $USER_HOME"
}

# =============================================================================
# 依赖安装
# =============================================================================

# 安装基础依赖
install_dependencies() {
    print_step "安装基础依赖和常用工具"

    case "$OS" in
        ubuntu|debian)
            print_info "更新软件包列表..."
            apt update

            print_info "安装基础工具..."
            apt install -y \
                curl wget git gpg unzip zsh sudo \
                build-essential \
                vim \
                tmux \
                htop \
                iperf3 mtr-tiny  \
                jq yq \
                zip gzip bzip2 xz-utils \
                rsync \
                ca-certificates 
            ;;
        centos|rhel|fedora)
            print_info "更新软件包列表..."
            yum update -y

            print_info "安装基础工具..."
            yum install -y \
                curl wget git gpg unzip zsh sudo \
                build-essential \
                vim \
                tmux \
                htop \
                iperf3 mtr-tiny  \
                jq yq \
                zip gzip bzip2 xz-utils \
                rsync \
                ca-certificates 
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    print_success "基础依赖和常用工具安装完成"
}

# =============================================================================
# 工具安装
# =============================================================================

# 安装 eza
install_eza() {
    print_step "安装 eza"

    if command -v eza &>/dev/null; then
        print_warning "eza 已安装，跳过"
        return
    fi

    case "$OS" in
        ubuntu|debian)
            apt install -y gpg
            mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
            chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            apt update
            apt install -y eza
            ;;
        *)
            print_warning "暂不支持在 $OS 上自动安装 eza"
            ;;
    esac

    print_success "eza 安装完成"
}

# 安装 fzf
install_fzf() {
    print_step "安装 fzf"

    local fzf_dir="$USER_HOME/.fzf"

    if [ -d "$fzf_dir" ]; then
        print_warning "fzf 已安装，跳过"
        return
    fi

    print_info "克隆 fzf 仓库到 $fzf_dir"
    sudo -u "$USERNAME" git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"

    print_info "安装 fzf"
    sudo -u "$USERNAME" bash "$fzf_dir/install" --all --no-bash --no-fish

    print_success "fzf 安装完成"
}

# 安装 zoxide
install_zoxide() {
    print_step "安装 zoxide"

    if command -v zoxide &>/dev/null; then
        print_warning "zoxide 已安装，跳过"
        return
    fi

    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

    # 复制到系统路径
    if [ -f "$USER_HOME/.local/bin/zoxide" ]; then
        cp "$USER_HOME/.local/bin/zoxide" /usr/local/bin/
    fi

    print_success "zoxide 安装完成"
}

# 安装 starship
install_starship() {
    print_step "安装 starship"

    if command -v starship &>/dev/null; then
        print_warning "starship 已安装，跳过"
        return
    fi

    curl -sS https://starship.rs/install.sh | sh -s -- -y

    print_success "starship 安装完成"
}

# 安装 tssh 和 trzsz
install_tssh_trzsz() {
    print_step "安装 tssh 和 trzsz"

    if command -v tssh &>/dev/null && command -v trzsz &>/dev/null; then
        print_warning "tssh 和 trzsz 已安装，跳过"
        return
    fi

    case "$OS" in
        ubuntu|debian)
            if [ -f "$(dirname "$0")/misc/install_tssh_trzsz.sh" ]; then
                print_info "执行 tssh 和 trzsz 安装脚本"
                bash "$(dirname "$0")/misc/install_tssh_trzsz.sh"
            else
                print_warning "未找到 install_tssh_trzsz.sh 脚本，跳过"
            fi
            ;;
        *)
            print_warning "暂不支持在 $OS 上自动安装 tssh 和 trzsz"
            ;;
    esac

    print_success "tssh 和 trzsz 安装完成"
}

# =============================================================================
# 配置文件设置
# =============================================================================

# 创建 .config 目录
create_config_dir() {
    print_step "创建配置目录"

    local config_dir="$USER_HOME/.config"

    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        chown -R "$USERNAME:$USERNAME" "$config_dir"
        print_success "已创建 $config_dir"
    else
        print_warning "$config_dir 已存在"
    fi
}

# 配置 starship
configure_starship() {
    print_step "配置 starship 主题"

    local config_dir="$USER_HOME/.config"
    local starship_config="$config_dir/starship.toml"

    # 确保目录存在
    mkdir -p "$config_dir"

    # 使用 preset 生成配置
    print_info "生成 nerd-font-symbols 主题配置"
    starship preset nerd-font-symbols -o "$starship_config"

    # 设置文件所有者
    chown "$USERNAME:$USERNAME" "$starship_config"

    print_success "starship 配置完成: $starship_config"
}

# 下载 zsh 配置文件
setup_zsh_config() {
    print_step "配置 zsh"

    # 下载 .zshrc
    print_info "下载 .zshrc"
    wget -q -O "$USER_HOME/.zshrc" "$REPO_URL/.zsh/.zshrc" || {
        print_error "下载 .zshrc 失败"
        return 1
    }

    # 下载 .common_alias.zsh
    print_info "下载 .common_alias.zsh"
    wget -q -O "$USER_HOME/.common_alias.zsh" "$REPO_URL/.zsh/.common_alias.zsh" || {
        print_error "下载 .common_alias.zsh 失败"
        return 1
    }

    # 下载 .func.zsh
    print_info "下载 .func.zsh"
    wget -q -O "$USER_HOME/.func.zsh" "$REPO_URL/.zsh/.func.zsh" || {
        print_warning "下载 .func.zsh 失败，跳过"
    }

    # 创建必要的目录
    mkdir -p "$USER_HOME/.cache/zsh"
    mkdir -p "$USER_HOME/.zinit"

    # 设置文件所有者
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.zshrc"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.common_alias.zsh"
    [ -f "$USER_HOME/.func.zsh" ] && chown -R "$USERNAME:$USERNAME" "$USER_HOME/.func.zsh"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.cache"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.zinit"

    print_success "zsh 配置文件下载完成"
}

# 设置 zsh 为默认 shell
set_default_shell() {
    print_step "设置默认 shell"

    if [ ! -f /bin/zsh ]; then
        print_error "zsh 未安装"
        return 1
    fi

    chsh -s /bin/zsh "$USERNAME"

    print_success "已将 $USERNAME 的默认 shell 设置为 zsh"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           Dotfiles 一键安装脚本                           ║
║                                                           ║
║  功能:                                                    ║
║    - 自动检测/创建用户                                    ║
║    - 安装 zsh + starship + eza + fzf + zoxide           ║
║    - 配置 dotfiles                                        ║
║    - 设置 starship nerd-font-symbols 主题                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"

    # 检查 root 权限
    check_root

    # 检测操作系统
    detect_os

    # 设置用户 (支持参数传入)
    setup_user "$1"

    # 安装依赖
    install_dependencies

    # 安装工具
    install_eza
    install_fzf
    install_zoxide
    install_starship
    install_tssh_trzsz

    # 配置 tmux (可选)
    read -p "是否配置 tmux? (y/n): " setup_tmux
    if [[ "$setup_tmux" =~ ^[Yy]$ ]]; then
        if [ -f "$(dirname "$0")/tmux/tmux_setup.sh" ]; then
            print_info "调用 tmux 配置脚本"
            sudo -u "$USERNAME" bash "$(dirname "$0")/tmux/tmux_setup.sh"
        else
            print_warning "未找到 tmux_setup.sh 脚本，跳过 tmux 配置"
        fi
    fi

    # 创建配置目录
    create_config_dir

    # 配置 starship
    configure_starship

    # 配置 zsh
    setup_zsh_config

    # 设置默认 shell
    set_default_shell

    # 完成
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}║             🎉 安装完成！                             ║${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}\n"

    print_info "用户: $USERNAME"
    print_info "主目录: $USER_HOME"
    print_info ""
    print_info "请执行以下命令以应用配置:"
    echo -e "  ${YELLOW}su - $USERNAME${NC}"
    echo -e "  或者"
    echo -e "  ${YELLOW}exec zsh${NC}"
    echo -e ""
    print_info "首次启动 zsh 时，zinit 会自动安装插件，请稍等片刻"
}

# 运行主函数
main "$@"
