#!/bin/bash

# 颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 重置颜色

# 全局变量
USERNAME=""
USER_PASSWORD=""
IP_ADDR=""

# 打印带颜色的信息
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

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "此脚本需要root权限，请使用sudo运行"
        exit 1
    fi
}
# 设置用户名
set_username() {
    read -p "请输入用户名: " USERNAME
    if [ -z "$USERNAME" ]; then
        print_error "用户名不能为空"
        exit 1
    fi
    
    # 检查用户是否存在
    if ! id "$USERNAME" &>/dev/null; then
        print_error "用户 '$USERNAME' 不存在"
        echo "请先创建用户，可以选择以下操作:"
        echo "1) 创建新用户"
        echo "2) 输入其他用户名"
        echo "3) 退出"
        
        read -p "请选择操作 [1-3]: " choice
        case $choice in
            1)
                create_user "$USERNAME"
                ;;
            2)
                set_username  # 再次调用函数来输入新的用户名
                ;;
            3)
                exit 0
                ;;
            *)
                print_error "无效选择"
                exit 1
                ;;
        esac
    else
        print_success "用户 '$USERNAME' 存在，继续操作"
    fi
}

function config_sshd() {
    print_info "正在配置sshd..."
    read -p "请输入ssh端口: " ssh_port
    sed -i 's/#Port 22/Port '$ssh_port'/' /etc/ssh/sshd_config
    # sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart sshd
    print_success "sshd配置完成"
}

# 创建新用户
create_user() {
    local new_username=${1:-""}
    echo -e "\n${CYAN}===== 创建新用户 =====${NC}"
    
    # 如果没有传入用户名，提示输入
    if [[ -z "$new_username" ]]; then
        while true; do
            read -p "请输入要创建的用户名: " new_username
            if [[ -z "$new_username" ]]; then
                print_error "用户名不能为空，请重新输入"
                continue
            elif id "$new_username" &>/dev/null; then
                print_error "用户 '$new_username' 已存在，请输入其他用户名"
                continue
            else
                USERNAME="$new_username"
                break
            fi
        done
    else
        # 检查传入的用户名是否已存在
        if id "$new_username" &>/dev/null; then
            print_error "用户 '$new_username' 已存在"
            read -p "是否使用其他用户名? (y/n): " change
            if [[ "$change" =~ ^[Yy]$ ]]; then
                create_user  # 递归调用，让用户输入新的用户名
                return
            else
                print_error "无法继续创建用户"
                exit 1
            fi
        else
            USERNAME="$new_username"
        fi
    fi
    
    # 创建用户
    print_info "正在创建用户: $USERNAME"
    useradd -m -s /bin/zsh -d /home/$USERNAME "$USERNAME"
    # 随机生成密码
    USER_PASSWORD=$(openssl rand -base64 12)
    print_info "用户 '$USERNAME' 的密码: $USER_PASSWORD"
    echo "$USER_PASSWORD" | passwd "$USERNAME"
    
    # 添加sudo权限
    print_info "为用户 '$USERNAME' 添加sudo权限"
    # 免密码
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

    print_success "用户 '$USERNAME' 创建成功！"
    
    # 保存用户名到配置文件
    # echo "export VPS_USER=$USERNAME" > /etc/profile.d/vps-init-user.sh
    # chmod +x /etc/profile.d/vps-init-user.sh
}


# 更新系统
function update_system() {
    print_info "正在更新系统..."
    apt update && apt upgrade -y
    print_success "系统更新完成"
}

# 安装基本工具
function install_basic_tools() {
    print_info "正在安装基本工具..."
    apt install -y curl wget git vim htop net-tools unzip jq iperf3 tmux
    print_success "基本工具安装完成"
}

# 安装常用工具
function install_common_tools() {
    print_info "正在安装常用工具..."
    apt install -y btop zsh sudo build-essential cargo fastfetch
    print_success "常用工具安装完成"
}

function install_starship() {
    print_info "正在安装starship..."
    curl -sS https://starship.rs/install.sh | sh
    print_success "starship安装完成"
}

function install_zoxide() {
    print_info "正在安装zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    print_success "zoxide安装完成"
}

# 安装Docker
function install_docker() {
    print_info "正在安装Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    bash get-docker.sh
    systemctl enable docker
    systemctl start docker
    
    # 添加当前用户到docker组
    if [[ -n "$USERNAME" ]]; then
        print_info "将用户 $USERNAME 添加到docker组"
        usermod -aG docker "$USERNAME"
    fi
    
    print_success "Docker安装完成"
}

# 配置BBR
function install_bbr() {
    print_info "正在安装BBR..."
    wget https://raw.githubusercontent.com/byJoey/Actions-bbr-v3/refs/heads/main/install.sh -O install.sh
    chmod +x install.sh
    ./install.sh
    print_success "BBR安装完成"
}

# 安装caddy
function install_caddy() {
    print_info "正在安装Caddy..."
    apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update
    apt install -y caddy
    print_success "Caddy安装完成"
}

# 安装eza
function install_eza() {
    print_info "正在安装eza..."
    apt install -y gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt update
    apt install -y eza
    print_success "eza安装完成"
}

#安装yazi
function install_yazi() {

    if ! command -v yazi &>/dev/null; then
        print_info "正在安装 yazi..."

        # 下載並解壓
        wget -O yazi.zip https://github.com/sxyazi/yazi/releases/download/nightly/yazi-x86_64-unknown-linux-gnu.zip
        unzip -o yazi.zip -d yazi_bin

        # 安裝執行檔
        install -Dm755 yazi_bin/yazi /usr/local/bin/yazi
        install -Dm755 yazi_bin/ya /usr/local/bin/ya

        # 補全（可選）
        install -Dm644 yazi_bin/completions/yazi.bash /usr/share/bash-completion/completions/yazi
        install -Dm644 yazi_bin/completions/_yazi /usr/share/zsh/site-functions/_yazi

        # 清理
        rm -rf yazi.zip yazi_bin

        print_success "yazi 安装完成，所有用户都可以使用了！"
    else
        print_done "yazi 已安装"
    fi
}

function install_fzf() {
    print_info "正在安装 fzf..."

    if ! command -v fzf &>/dev/null; then fastfetch
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        print_success "fzf 安装完成"
    else
        print_done "fzf 已安装"
    fi
}

function install_nvim() {
    print_info "正在安装 nvim..."
    apt install -y neovim
    print_success "nvim 安装完成"
}


function install_nvim() {
    print_info "正在安装 Neovim..."

    if ! command -v nvim &>/dev/null; then
        wget -O nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        mkdir -p nvim-extract
        tar -xzf nvim.tar.gz -C nvim-extract --strip-components=1

        # 移動可執行檔到 /usr/local/bin
        install -Dm755 nvim-extract/bin/nvim /usr/local/bin/nvim

        # 清理
        rm -rf nvim.tar.gz nvim-extract

        print_success "Neovim 安装完成，所有用户都可以使用 'nvim'"
    else
        print_done "Neovim 已安装"
    fi
}

function install_lazyvim() {
    print_info "正在安装 LazyVim..."

    git clone https://github.com/LazyVim/starter /etc/nvim
    rm -rf /etc/nvim/.git

    print_success "LazyVim 配置安装完成，路径：/etc/nvim"
}

function install_serverstatus_client() {
    print_info "正在安装 ServerStatus Rust 客户端..."

    read -p "请输入 ServerStatus 服务端地址（如 http://example.com:8080）: " ss_client_url
    read -p "请输入上报用户名: " ss_client_u
    read -p "请输入上报密码: " ss_client_p

    apt install -y vnstat

    set -e
    WORKSPACE="/opt/ServerStatus"
    OS_ARCH="x86_64"
    TMPDIR="/tmp/serverstatus-client"

    mkdir -p "$WORKSPACE"
    rm -rf "$TMPDIR"
    mkdir -p "$TMPDIR"

    print_info "获取最新版本号..."
    latest_version=$(curl -m 10 -sL "https://api.github.com/repos/zdz/ServerStatus-Rust/releases/latest" \
        | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/[\", ]//g')

    print_info "下载客户端压缩包 version=${latest_version}..."
    wget --no-check-certificate -qO "${TMPDIR}/client-${OS_ARCH}.zip" \
        "https://github.com/zdz/ServerStatus-Rust/releases/download/${latest_version}/client-${OS_ARCH}-unknown-linux-musl.zip"

    print_info "解压到临时目录..."
    unzip -o "${TMPDIR}/client-${OS_ARCH}.zip" -d "$TMPDIR"

    print_info "移动文件到 $WORKSPACE..."
    mv -f "$TMPDIR"/stat_client "$WORKSPACE/"
    mv -f "$TMPDIR"/stat_client.service "$WORKSPACE/"

    print_info "生成 systemd 服务..."
    cp "$WORKSPACE/stat_client.service" /etc/systemd/system/stat_client.service
    sed -i "s|^ExecStart=.*|ExecStart=${WORKSPACE}/stat_client -a \"${ss_client_url}/report\" -u ${ss_client_u} -p ${ss_client_p} -n --vnstat-mr 11|" /etc/systemd/system/stat_client.service

    print_info "启用并启动服务..."
    systemctl daemon-reload
    systemctl enable stat_client
    systemctl restart stat_client

    rm -rf "$TMPDIR"
    print_success "✅ ServerStatus 客户端安装完成并已启动"
    echo "📄 配置文件位置：/etc/systemd/system/stat_client.service"
    echo "🧾 查看日志：journalctl -u stat_client -f -n 100"
    echo "修改后运行 systemctl daemon-reload && systemctl restart stat_client 重启服务"
}

function setup_fail2ban() {
    print_info "正在安装 fail2ban..."
    apt install -y fail2ban
    print_success "fail2ban 安装完成"

}

function setup_zsh() {
    # 安装 zsh
    if ! command -v zsh &>/dev/null; then
        print_info "正在安装 zsh..."
        apt install -y zsh
        print_success "zsh 安装完成"
    fi
    

    # 为用户安装 starship
    if ! sudo -u "$USERNAME" command -v starship &>/dev/null; then
        print_info "为 $USERNAME 安装 starship..."
        sudo -u "$USERNAME" bash -c 'curl -sS https://starship.rs/install.sh | bash -s -- -y'
        print_success "starship 安装完成"
    fi

    # 为用户安装 zoxide
    if ! sudo -u "$USERNAME" command -v zoxide &>/dev/null; then
        print_info "为 $USERNAME 安装 zoxide..."
        sudo -u "$USERNAME" bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
        print_success "zoxide 安装完成"
    fi

    # 添加 PATH、初始化代码 到该用户的 .zshrc
    local zshrc_path="/home/$USERNAME/.zshrc"
    [ "$USERNAME" = "root" ] && zshrc_path="/root/.zshrc"

    if ! grep -q 'starship init' "$zshrc_path" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' >> "$zshrc_path"
        echo 'eval "$(starship init zsh)"' >> "$zshrc_path"
    fi

    if ! grep -q 'zoxide init' "$zshrc_path" 2>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> "$zshrc_path"
    fi

    print_success "$USERNAME 的 zsh 配置完成 ✅"
}

show_menu() {
    echo "============= 基本信息 ============="
    echo "当前操作用户：$USERNAME"
    echo "当前操作用户密码：$USER_PASSWORD"
    echo "当前VPS IP：$IP_ADDR"
    echo "系统版本：$(lsb_release -a)"
    echo "============= 安装选项 ============="
    echo
    echo "可用选项:"
    echo "1) 安装常用工具"
    echo "2) 配置sshd"
    echo "3) 安装Docker"
    echo "4) 安装BBR"
    echo "5) 安装caddy"
    echo "6) 安装eza"
    echo "7) 安装fzf"
    echo "8) 安装yazi"
    echo "9) 安装 Neovim"
    echo "10) 安装 LazyVim"
    echo "11) 安装 ServerStatus 客户端"
    echo "a) 安装全部"
    echo "b) 安装 zsh 配置"
    echo "c) 安装 fail2ban"
    echo "0) 退出"
    echo
    echo "======================================"
    echo
}

function install_all() {
    install_common_tools
    config_sshd
    install_docker
    install_bbr
    install_caddy
    install_eza
    install_fzf
    install_yazi
    install_nvim
    install_lazyvim
    install_serverstatus_client
}
# 执行选中的功能
execute_function() {
    case $1 in
        1) install_common_tools ;;
        2) config_sshd ;;
        3) install_docker ;;
        4) install_bbr ;;
        5) install_caddy ;;
        6) install_eza ;;
        7) install_yazi ;;
        8) install_nvim ;;
        9) install_lazyvim ;;
        10) install_serverstatus_client ;;
        11) install_starship ;;
        12) install_zoxide ;;
        a) install_all ;;
        b) setup_fail2ban ;;
        *) print_warning "无效选项: $1" ;;
    esac
}

# 主函数
main() {

    IP_ADDR=$(curl -4 -sSL ifconfig.me)

    check_root
    # update system
    update_system 
    # install basic tools
    install_basic_tools
    
    # 设置用户名
    set_username
    
    if [ $# -eq 0 ]; then
        # 交互式模式
        while true; do
            show_menu
            read -p "请输入要安装的项目编号（多个编号用空格分隔，输入0退出）: " choices
            
            if [ "$choices" = "0" ]; then
                echo -e "\n${GREEN}初始化完成${NC}"
                echo "退出脚本"
                exit 0
            fi
            
            for choice in $choices; do
                execute_function $choice
            done
        done
    else
        # 命令行参数模式
        for choice in "$@"; do
            execute_function $choice
        done
        
        echo -e "\n${GREEN}初始化完成${NC}"
    fi
}

# 运行主函数
main "$@"