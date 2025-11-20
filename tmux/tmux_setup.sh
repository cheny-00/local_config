#!/usr/bin/env bash

# =============================================================================
# Tmux 一键配置脚本
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://raw.githubusercontent.com/cheny-00/local_config/main"
TMUX_CONF="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

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

# =============================================================================
# 检查 tmux
# =============================================================================

check_tmux() {
    print_step "检查 tmux"

    if ! command -v tmux &>/dev/null; then
        print_error "tmux 未安装"
        print_info "请先安装 tmux:"
        echo -e "  ${YELLOW}Ubuntu/Debian:${NC} sudo apt install tmux"
        echo -e "  ${YELLOW}CentOS/RHEL:${NC}   sudo yum install tmux"
        exit 1
    fi

    local tmux_version=$(tmux -V)
    print_success "已安装 $tmux_version"
}

# =============================================================================
# TPM (Tmux Plugin Manager) 安装
# =============================================================================

install_tpm() {
    print_step "安装 TPM (Tmux Plugin Manager)"

    if [ -d "$TPM_DIR" ]; then
        print_warning "TPM 已安装，跳过"
        return
    fi

    print_info "克隆 TPM 仓库到 $TPM_DIR"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"

    print_success "TPM 安装完成"
}

# =============================================================================
# 配置文件设置
# =============================================================================

configure_tmux() {
    print_step "配置 tmux"

    local source_config="$SCRIPT_DIR/.tmux.conf"

    # 备份已有配置
    if [ -f "$TMUX_CONF" ]; then
        local backup="$TMUX_CONF.backup.$(date +%s)"
        print_warning "检测到已有配置，备份至: $backup"
        mv "$TMUX_CONF" "$backup"
    fi

    # 复制或下载配置文件
    if [ -f "$source_config" ]; then
        print_info "从本地复制配置文件"
        cp "$source_config" "$TMUX_CONF"
    else
        print_info "从远程下载配置文件"
        if command -v curl &>/dev/null; then
            curl -fsSL "$REPO_URL/tmux/.tmux.conf" -o "$TMUX_CONF"
        elif command -v wget &>/dev/null; then
            wget -qO "$TMUX_CONF" "$REPO_URL/tmux/.tmux.conf"
        else
            print_error "未找到 curl 或 wget，无法下载配置文件"
            exit 1
        fi

        if [ $? -ne 0 ]; then
            print_error "配置文件下载失败，请检查网络或 URL"
            exit 1
        fi
    fi

    print_success "tmux 配置文件设置完成: $TMUX_CONF"
}

# =============================================================================
# 插件安装
# =============================================================================

install_plugins() {
    print_step "安装 tmux 插件"

    if [ ! -d "$TPM_DIR" ]; then
        print_error "TPM 未安装，无法安装插件"
        return 1
    fi

    print_info "通过 TPM 安装插件（可能需要一些时间）"

    # 设置环境变量
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"

    # 如果 tmux 正在运行，重载配置
    if pgrep tmux &>/dev/null; then
        print_info "检测到 tmux 正在运行，重载配置..."
        tmux source "$TMUX_CONF" 2>/dev/null || true
    fi

    # 使用 TPM 脚本安装插件
    bash "$TPM_DIR/bin/install_plugins"

    print_success "tmux 插件安装完成"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           Tmux 一键配置脚本                              ║
║                                                           ║
║  功能:                                                    ║
║    - 检查 tmux                                            ║
║    - 安装 TPM (Tmux Plugin Manager)                      ║
║    - 配置 .tmux.conf                                      ║
║    - 安装 tmux 插件                                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"

    # 检查 tmux
    check_tmux

    # 安装 TPM
    install_tpm

    # 配置 tmux
    configure_tmux

    # 安装插件
    install_plugins

    # 完成
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}║             🎉 Tmux 配置完成！                        ║${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}\n"

    print_info "配置文件: $TMUX_CONF"
    echo ""
    print_warning "提示:"
    echo -e "  1. 如果你现在就在 tmux 里，请运行: ${YELLOW}tmux source ~/.tmux.conf${NC}"
    echo -e "  2. 如果遇到显示问题，建议运行: ${YELLOW}tmux kill-server${NC} 然后重新进入"
    echo -e "  3. 请确保你的终端使用的是 ${YELLOW}Nerd Fonts${NC} 字体"
    echo ""
    print_info "常用快捷键:"
    echo -e "  ${CYAN}Ctrl+b I${NC}  - 手动安装/更新插件"
    echo -e "  ${CYAN}Ctrl+b U${NC}  - 更新插件"
    echo ""
}

# 运行主函数
main "$@"
