# ============================================================
# GENERATED FILE - DO NOT EDIT
# 源: 私有 chezmoi dotfiles 仓库的 linux 渲染，手改必被覆盖
# 更新: 在 Mac 上运行 dotfiles 仓库的 .scripts/sync-server-configs.sh
# ============================================================

# 服务器：SSH 登录展示 fastfetch（每会话一次）
if [[ -n "$SSH_CONNECTION" && -z "$FASTFETCH_SHOWN" && $- == *i* ]]; then
  export FASTFETCH_SHOWN=1
  command -v fastfetch >/dev/null && fastfetch
fi

# ------------------ 基础环境变量 ------------------
export STARSHIP_PYTHON_DISABLED=true
export ZINIT_HOME="${HOME}/.zinit/bin"
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export TERM=xterm-256color

# ------------------ PATH 设置 ------------------
export PATH="$HOME/.local/bin:$PATH"

# ------------------ 加载自定义函数 ------------------
[[ -f "$HOME/.func.zsh" ]] && source "$HOME/.func.zsh"

# ------------------ 安装 Zinit（若未安装） ------------------
if [[ ! -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  mkdir -p ~/.zinit
  git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi

# ------------------ 非交互模式直接返回 ------------------
[[ $- != *i* ]] && return

# ------------------ 加载 Zinit ------------------
source "${ZINIT_HOME}/zinit.zsh"

# ------------------ 补全系统（只调用一次）------------------
# opencli completion
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit
mkdir -p ~/.cache/zsh
# 每天只检查一次 zcompdump（加速启动）
if [[ -n ~/.cache/zsh/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.cache/zsh/.zcompdump
else
  compinit -C -d ~/.cache/zsh/.zcompdump
fi

# ------------------ Edit Command Line ------------------
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x' edit-command-line

# ------------------ 核心插件（立即加载）------------------

# 自动建议（右侧灰字）
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions

# fzf 补全增强
zinit ice lucid
zinit light Aloxaf/fzf-tab


# ------------------ Turbo Mode 插件（延迟加载）------------------

# 命令语法高亮
zinit ice wait'0' lucid atinit"zpcompinit; zpcdreplay"
zinit light zsh-users/zsh-syntax-highlighting

# 历史模糊搜索
zinit ice wait'0' lucid
zinit load zdharma/history-search-multi-word

# fzf 本体
zinit ice wait'0' lucid
zinit light junegunn/fzf
[[ ! "$PATH" == *$HOME/.fzf/bin* ]] && export PATH="$HOME/.fzf/bin:$PATH"

# z 跳目录
zinit ice wait'0' lucid
zinit light rupa/z

# zoxide 智能跳目录（懒加载）
zinit ice wait'0' lucid as"null" from"gh-r" sbin"zoxide" \
    atload'eval "$(zoxide init zsh)"'
zinit light ajeetdsouza/zoxide

# Git 补全
zinit ice wait'0' lucid blockf
zinit light zsh-users/zsh-completions

# Git 快捷别名
zinit ice wait'0' lucid
zinit snippet OMZ::lib/git.zsh
zinit ice wait'0' lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Docker 插件
zinit ice wait'1' lucid
zinit snippet OMZ::plugins/docker/docker.plugin.zsh

# zsh-you-should-use
zinit ice wait'1' lucid
zinit light MichaelAquilina/zsh-you-should-use
ZSH_YOU_SHOULD_USE_EXCLUDE=('ls' 'cd')

# ----------------------- 自定义 ------------------------------

[ -f ~/.zsh/s3cmd/share-images.zsh ] && source ~/.zsh/s3cmd/share-images.zsh


# ------------------ Starship Prompt（缓存初始化脚本）------------------
if command -v starship >/dev/null; then
  _starship_cache="$HOME/.cache/starship/init.zsh"
  if [[ ! -f "$_starship_cache" ]] || [[ "$(command -v starship)" -nt "$_starship_cache" ]]; then
      mkdir -p "${_starship_cache:h}"
      starship init zsh > "$_starship_cache"
  fi
  source "$_starship_cache"
fi

# ------------------ Zsh 行为优化 ------------------
setopt AUTO_CD
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ------------------ 按键绑定 ------------------
bindkey -e
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# ------------------ 常用别名 ------------------

[ -f ~/.alias.zsh ] && source ~/.alias.zsh
[ -f ~/.ai_cli_alias.zsh ] && source ~/.ai_cli_alias.zsh


# eza (ls 替代)
alias ls='eza --icons --group-directories-first'
alias l='eza --icons'
alias la='eza -a --icons'
alias ll='eza -lah --icons'
alias lt='eza -lah --sort=modified --icons'
alias lS='eza -lah --sort=size --icons'
alias lsd='eza -l --icons -D'
alias tree='eza -T --icons -L 2'
alias lp='eza -l --no-time --no-user --no-permissions --icons'

# 目录导航
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'

# 文件操作
alias dus='du -sh ./* 2>/dev/null'
alias pathls='echo $PATH | tr ":" "\n" | xargs -n1 ls'

# 编辑器
alias nv="nvim"
alias zc='nvim ~/.zshrc'
alias zs='source ~/.zshrc'

# Python
alias python='python3'

# Docker
alias dco="docker compose"
alias dcu="docker compose up"
alias dcd="docker compose down"
alias dcb="docker compose build"
alias dcps="docker compose ps"
alias dcr="docker compose run"

# Tmux
alias tl="tmux list-session"
alias tkss="tmux kill-session -t"
alias ta="tmux attach -t"
alias tn="tmux new-session -s"

# 通用工具
alias week="date +%V"
command -v with-readline >/dev/null && alias sftp="with-readline sftp"
alias ts="tailscale"
alias lg="lazygit"
alias nt="nexttrace"

# SSH 快捷方式
alias s="tssh"
alias lhc="lftp -p 29529 -u chy, sftp://h.chy.moe"

# fzf 相关
alias f='cd $(ls -d */ | fzf)'
alias fb="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"
alias fcat="fzf --preview 'cat {}'"

# 本地私密环境变量（不进 dotfiles 仓库）
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
