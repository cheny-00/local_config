#!/usr/bin/env bash

# =============================================================================
# Dotfiles 一键安装脚本
# =============================================================================
#
# 用法:
#   bash init.sh [OPTIONS]
#
# 选项:
#   --help              显示此帮助信息
#   -u, --user NAME     指定用户名（默认交互式询问）
#   -h, --hostname NAME 指定主机名（默认不修改）
#   -k, --ssh-key       配置 SSH 安全
#   -t, --tmux          配置 tmux
#
# 示例:
#   bash init.sh --help                           # 显示帮助
#   bash init.sh -u chy                           # 创建用户 chy
#   bash init.sh -u chy -h my-server              # 创建用户并设置主机名
#   bash init.sh -u chy -h my-server -k -t        # 全部配置
#   bash init.sh --user chy --hostname my-server  # 使用长选项
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
# dotfiles 统一由 chezmoi 仓库提供（本仓库只负责装工具/引导）
# 私有仓库在非交互环境需要带凭证的 URL，见 --dotfiles 说明
DOTFILES_REPO="https://github.com/cheny-00/dotfiles.git"

# 命令行参数变量
ARG_USERNAME=""
ARG_HOSTNAME=""
ARG_SETUP_SSH="n"
ARG_SETUP_TMUX="n"
ARG_DOTFILES=""

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

# 显示帮助信息
show_help() {
    cat << EOF
${CYAN}
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           Dotfiles 一键安装脚本                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
${NC}
用法:
  bash init.sh [OPTIONS]

选项:
  --help              显示此帮助信息
  -u, --user NAME     指定用户名（默认交互式询问）
  -h, --hostname NAME 指定主机名（默认不修改）
  -k, --ssh-key       配置 SSH 安全
  -t, --tmux          配置 tmux
  -d, --dotfiles URL  dotfiles 仓库地址（默认 $DOTFILES_REPO）
                      私有仓库用 https://<token>@github.com/... 形式

功能:
  - 自动检测/创建用户
  - 安装 zsh + starship + eza + fzf + zoxide
  - 配置 vim 完整环境
  - 配置 dotfiles
  - 设置 starship nerd-font-symbols 主题
  - SSH 公钥配置与安全加固（可选）

示例:
  bash init.sh --help
    显示此帮助信息

  bash init.sh -u chy
    创建用户 chy，其他使用默认配置

  bash init.sh -u chy -h my-server
    创建用户 chy，设置主机名为 my-server

  bash init.sh -u chy -h my-server -k -t
    创建用户，设置主机名，配置 SSH 安全和 tmux

  bash init.sh --user chy --hostname my-server --ssh-key
    使用长选项格式

  bash init.sh
    交互式模式，询问所有配置选项

EOF
    exit 0
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                ;;
            -u|--user)
                ARG_USERNAME="$2"
                shift 2
                ;;
            -h|--hostname)
                ARG_HOSTNAME="$2"
                shift 2
                ;;
            -k|--ssh-key)
                ARG_SETUP_SSH="y"
                shift
                ;;
            -t|--tmux)
                ARG_SETUP_TMUX="y"
                shift
                ;;
            -d|--dotfiles)
                ARG_DOTFILES="$2"
                shift 2
                ;;
            *)
                print_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
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
    mkdir -p /etc/sudoers.d
    echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
    chmod 440 /etc/sudoers.d/$user

    print_success "已为用户 $user 添加 sudo 权限"

    # 复制 root 的 SSH 密钥到新用户
    if [ -f /root/.ssh/authorized_keys ]; then
        print_info "正在复制 SSH 密钥到用户 $user"
        local user_home="/home/$user"
        mkdir -p "$user_home/.ssh"

        # 使用追加方式，避免覆盖用户已有的密钥
        cat /root/.ssh/authorized_keys >> "$user_home/.ssh/authorized_keys"

        chmod 700 "$user_home/.ssh"
        chmod 600 "$user_home/.ssh/authorized_keys"
        chown -R "$user:$user" "$user_home/.ssh"
        print_success "SSH 密钥复制完成，可以使用 SSH 密钥登录用户 $user"
    else
        print_warning "未找到 root 的 SSH 密钥，请手动配置"
    fi
}

# 设置主机名
setup_hostname() {
    local new_hostname="$1"

    # 如果没有提供主机名，跳过
    if [ -z "$new_hostname" ]; then
        return
    fi

    print_step "设置主机名"

    local current_hostname=$(hostname)
    if [ "$current_hostname" = "$new_hostname" ]; then
        print_info "主机名已经是 $new_hostname，跳过"
        return
    fi

    print_info "当前主机名: $current_hostname"
    print_info "新主机名: $new_hostname"

    # 使用 hostnamectl 设置主机名（systemd 系统）
    if command -v hostnamectl &>/dev/null; then
        hostnamectl set-hostname "$new_hostname"
    else
        # 传统方法
        echo "$new_hostname" > /etc/hostname
        hostname "$new_hostname"
    fi

    # 更新 /etc/hosts
    if grep -q "^127.0.1.1" /etc/hosts; then
        # 如果存在 127.0.1.1，更新它
        sed -i "s/^127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
    else
        # 如果不存在，添加在 127.0.0.1 后面
        sed -i "/^127.0.0.1/a 127.0.1.1\t$new_hostname" /etc/hosts
    fi

    print_success "主机名已设置为: $new_hostname"
    print_warning "主机名更改可能需要重新登录才能生效"
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

        if [ -t 0 ]; then
            read -p "是否创建该用户? (y/n): " create_choice
        else
            create_choice="y"
            print_info "非交互模式，自动创建用户"
        fi

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

    # 安装到系统路径
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

    # 复制到系统路径（安装脚本会安装到 /root/.local/bin）
    if [ -f /root/.local/bin/zoxide ]; then
        cp /root/.local/bin/zoxide /usr/local/bin/
        print_info "已复制 zoxide 到 /usr/local/bin"
    elif [ -f "$HOME/.local/bin/zoxide" ]; then
        cp "$HOME/.local/bin/zoxide" /usr/local/bin/
        print_info "已复制 zoxide 到 /usr/local/bin"
    else
        print_warning "未找到 zoxide 二进制文件，可能需要手动配置 PATH"
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

# 通过 chezmoi 拉取 dotfiles（.zshrc/.vimrc/.tmux.conf 等统一来源）
setup_dotfiles() {
    print_step "配置 dotfiles (chezmoi)"

    local repo="${ARG_DOTFILES:-$DOTFILES_REPO}"
    local chezmoi_bin="$USER_HOME/.local/bin/chezmoi"

    # 安装 chezmoi 到目标用户的 ~/.local/bin
    if [ ! -x "$chezmoi_bin" ]; then
        print_info "安装 chezmoi"
        sudo -u "$USERNAME" sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$USER_HOME/.local/bin" || {
            print_error "chezmoi 安装失败"
            return 1
        }
    fi

    # 初始化并应用配置
    print_info "chezmoi init --apply $repo"
    if ! sudo -u "$USERNAME" "$chezmoi_bin" init --apply "$repo"; then
        print_warning "chezmoi init 失败。私有仓库需要凭证，例如:"
        print_warning "  --dotfiles 'https://<只读token>@github.com/cheny-00/dotfiles.git'"
        print_warning "稍后可手动执行: chezmoi init --apply <repo>"
        return 0
    fi

    # .zshrc 依赖的目录
    mkdir -p "$USER_HOME/.cache/zsh" "$USER_HOME/.zinit"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.cache" "$USER_HOME/.zinit"

    print_success "dotfiles 应用完成"
}

# 配置 vim（.vimrc 来自 chezmoi，这里只做插件引导）
setup_vim_config() {
    print_step "配置 vim"

    # 创建 vim 目录结构
    print_info "创建 vim 目录结构"
    mkdir -p "$USER_HOME/.vim/files/"{backup,undo,swap,info}
    mkdir -p "$USER_HOME/.vim/"{autoload,plugged}

    # 下载 vim-plug 插件管理器
    print_info "安装 vim-plug 插件管理器"
    curl -fsSLo "$USER_HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || {
        print_warning "下载 vim-plug 失败，请手动安装"
    }

    # 设置文件所有者
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.vim"

    print_success "vim 配置完成"
    print_info "首次使用 vim 时，运行 :PlugInstall 安装插件"
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
    # 解析命令行参数
    parse_arguments "$@"

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
║    - SSH 公钥配置与安全加固                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"

    # 检查 root 权限
    check_root

    # 检测操作系统
    detect_os

    # 设置主机名
    setup_hostname "$ARG_HOSTNAME"

    # 设置用户
    setup_user "$ARG_USERNAME"

    # 安装依赖
    install_dependencies

    # 安装工具
    install_eza
    install_fzf
    install_zoxide
    install_starship
    install_tssh_trzsz

    # 创建配置目录
    create_config_dir

    # 配置 starship
    configure_starship

    # 拉取 dotfiles（zsh/vim/tmux 配置）
    setup_dotfiles

    # 配置 vim 插件
    setup_vim_config

    # 配置 tmux (可选，需在 dotfiles 应用之后，.tmux.conf 来自 chezmoi)
    local setup_tmux_choice="$ARG_SETUP_TMUX"
    if [ "$setup_tmux_choice" != "y" ]; then
        if [ -t 0 ]; then
            read -p "是否配置 tmux? (y/n): " setup_tmux_choice
        else
            setup_tmux_choice="n"
        fi
    fi
    if [[ "$setup_tmux_choice" =~ ^[Yy]$ ]]; then
        if [ -f "$(dirname "$0")/tmux/tmux_setup.sh" ]; then
            print_info "调用 tmux 配置脚本"
            sudo -u "$USERNAME" bash "$(dirname "$0")/tmux/tmux_setup.sh"
        else
            print_warning "未找到 tmux_setup.sh 脚本，跳过 tmux 配置"
        fi
    fi

    # 设置默认 shell
    set_default_shell

    # 配置 SSH 安全（可选）
    local setup_ssh_choice="$ARG_SETUP_SSH"
    if [ "$setup_ssh_choice" != "y" ]; then
        if [ -t 0 ]; then
            read -p "是否配置 SSH 安全? (y/n): " setup_ssh_choice
        else
            setup_ssh_choice="n"
        fi
    fi
    if [[ "$setup_ssh_choice" =~ ^[Yy]$ ]]; then
        if [ -f "$(dirname "$0")/ssh/ssh_security.sh" ]; then
            print_info "调用 SSH 安全配置脚本"
            bash "$(dirname "$0")/ssh/ssh_security.sh" full "$USERNAME"
        else
            print_warning "未找到 ssh_security.sh 脚本，跳过 SSH 配置"
        fi
    fi

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
