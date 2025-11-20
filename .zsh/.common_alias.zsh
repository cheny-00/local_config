
# fzf
if command -v fzf &>/dev/null; then
    alias f='cd $(ls -d */ | fzf)'
    alias fb="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"
    alias fcat="fzf --preview 'cat {}'"
fi

# tmux
alias tl="tmux list-session"
alias tkss="tmux kill-session -t"
alias ta="tmux attach -t"
alias tn="tmux new-session -s"


# docker compose

alias dco="docker compose"
alias dcu="docker compose up"
alias dcd="docker compose down"
alias dcb="docker compose build"
alias dcps="docker compose ps"
alias dcr="docker compose run"

# docker
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"

# cd
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c='clear'

# eza
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    # 基本 ls 显示（带图标）
    alias l='eza --icons'
    # 显示隐藏文件（简洁版）
    alias la='eza -a --icons'

    # 详细列表 + 隐藏文件（完整查看）
    alias ll='eza -lah --icons'

    # 按时间排序（最近修改的排前面）
    alias lt='eza -lah --sort=modified --icons'

    # 按大小排序（最大文件在前）
    alias lS='eza -lah --sort=size --icons'

    # 只列出目录
    alias lsd='eza -l --icons -D'  # eza 的 -D 代表只列目录

    # 查看树状结构（递归2层）
    alias tree='eza -T --icons -L 2'

    # 列出权限信息（简洁）
    alias lp='eza -l --no-time --no-user --no-permissions --icons'
fi

# path
alias pathls='echo $PATH | tr ":" "\n" | xargs -n1 ls'

# du
alias dus='du -sh ./* 2>/dev/null'

# common
alias python='python3'
# caddy
if command -v caddy &>/dev/null; then
    # 核心管理
    alias cadfmt="caddy fmt --overwrite"      # 必用：格式化并覆写当前目录的 Caddyfile
    alias cadval="caddy validate"             # 验证配置文件语法是否正确
    alias cadrel="caddy reload"               # 平滑重载配置（不中断服务）
    alias cadrun="caddy run"                  # 前台运行（调试用）
    alias cadstop="caddy stop"                # 停止运行

    # 快速编辑配置 (假设在当前目录或 /etc/caddy/Caddyfile，可根据习惯修改)
    alias vccf="vim /etc/caddy/Caddyfile"

    # 进阶工具
    alias cadver="caddy version"
    alias cadlist="caddy list-modules"
fi

# caddy service (如果你使用 systemd/apt 安装的版本，推荐保留这些)
alias cadst="sudo systemctl status caddy"       # 查看服务状态
alias cadsr="sudo systemctl reload caddy"       # 重载服务配置 (更安全)
alias cadrst="sudo systemctl restart caddy"     # 重启服务
alias cadlog="sudo journalctl -u caddy -f -n 100" # 实时查看最近100行日志

alias zc='nvim ~/.zshrc'
alias zs='source ~/.zshrc'
alias nv="nvim"
alias s="tssh"