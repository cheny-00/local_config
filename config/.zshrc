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

# TERM 故意不在这里写死（2026-07-12 移除 export TERM=xterm-256color）。
# TERM 是查 terminfo 的钥匙，硬写死等于对所有程序谎报终端能力：
# 在 tmux 里会盖掉 tmux-256color，在 kitty 里会盖掉 xterm-kitty，
# 连带影响斜体/undercurl/图形协议探测（yazi 图片预览就吃这一套）。
# 让 kitty 和 tmux 各自声明真实身份即可。
# 若 ssh 老服务器报 unknown terminal，是「远端 terminfo 缺失」，
# 正解在远端补：infocmp -x | ssh <host> 'tic -x -'，而不是本地全局降级。

# ------------------ PATH 设置 ------------------
# 去重（2026-09-23）：tmux / 嵌套 login shell 每层都会再 prepend 一遍，实测 42 条里 8 条重复。
# 同时删掉了 /usr/local/opt/ruby/bin、/usr/local/lib/ruby/gems/3.0.0/bin（Intel brew 遗留，已不存在）。
typeset -U path PATH
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
# (#q...) 限定符要 extended_glob 才认；此前没开，条件恒真 → 每个 shell 都完整 compinit + 重写 dump
#（2026-09-23 实测）。只在匿名函数里局部开：全局开会让 `git reset HEAD^` 报 no matches found。
() {
  setopt local_options extended_glob
  if [[ -n ~/.cache/zsh/.zcompdump(#qN.mh+24) ]]; then
    compinit -d ~/.cache/zsh/.zcompdump
  else
    compinit -C -d ~/.cache/zsh/.zcompdump
  fi
}

# ------------------ Edit Command Line ------------------
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x' edit-command-line

# ------------------ 核心插件（立即加载）------------------

# fzf 补全增强（fzf-tab 要求：compinit 之后、任何包装 widget 的插件之前加载）
zinit ice lucid
zinit light Aloxaf/fzf-tab

# fzf-tab 预览 + tmux 浮窗（2026-09-23）。不在 tmux 里时 ftb-tmux-popup 自动退回普通 fzf。
# 故意不加「环境变量值预览」：~/.zshrc.local 里有 API key，echo $<Tab> 会明文上屏。
zstyle ':completion:*' menu no                       # 交给 fzf-tab，不弹 zsh 自带菜单
zstyle ':completion:*:descriptions' format '[%d]'    # 显示分组名，< > 切组
zstyle ':completion:*:git-checkout:*' sort false     # 分支按最近提交排，不按字母
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' use-fzf-default-opts yes         # 默认会清空 FZF_DEFAULT_OPTS → fzf 退回暗色方案
# 浮窗按内容定尺寸，带预览的场景给大一点的下限，否则预览栏被挤成一条
zstyle ':fzf-tab:*' popup-min-size 60 10
zstyle ':fzf-tab:complete:(cd|__zoxide_z|pushd|nvim|vim|cat|bat|less|head|tail|git-*|kill):*' popup-min-size 110 24
# 目录：cd / z 预览目录内容
zstyle ':fzf-tab:complete:(cd|__zoxide_z|pushd):*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
# 文件：编辑/查看类命令预览内容，目录则列出
zstyle ':fzf-tab:complete:(nvim|vim|cat|bat|less|head|tail):*' fzf-preview '[[ -d $realpath ]] && eza -1 --color=always $realpath || bat -n --color=always --line-range :200 $realpath'
# git：改动文件看 diff（装了 delta 就经 delta 渲染，只有 Mac 装了），其余看 log
if (( $+commands[delta] )); then
  _ftb_gitdiff='git diff $word | delta --width=${FZF_PREVIEW_COLUMNS:-80}'
else
  _ftb_gitdiff='git diff --color=always $word'
fi
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview $_ftb_gitdiff
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'case $group in ("modified file") '$_ftb_gitdiff' ;; (*) git log --color=always --oneline -20 $word ;; esac'
unset _ftb_gitdiff
# 进程：kill <Tab> 看完整命令行（BSD ps 语法；Linux 的 ps 也认 -p/-o/-ww）
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps -p $word -o command= -ww'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview-window=down:3:wrap

# 自动建议（右侧灰字）
# MANUAL_REBIND：默认每次出提示符都把所有 widget 重绑一遍（实测 7.5ms/次），改成只在第一次提示符时绑。
# 之后才加载的插件新建的 widget 就不会被它包住；本文件里没有这种情况（fsh 只是在外面再包一层），
# 灰字、→ 采纳、fsh 高亮都实测正常（2026-09-24）。
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions


# ------------------ Turbo Mode 插件（延迟加载）------------------

# 历史搜索（Ctrl+R）：装了 atuin 就用 atuin（2026-09-24，Mac，只本地不同步，配置 ~/.config/atuin），
# 否则 history-search-multi-word（zdharma 原仓库已停更，用 continuum 维护版）。二者都抢 Ctrl+R，只能留一个。
# --disable-up-arrow：上方向键保持 zsh 原样。init 脚本缓存，同 zoxide。
# 在「非交互直接返回」之后，Claude / Codex 跑的命令不会进 atuin。
if (( $+commands[atuin] )); then
  _atuin_cache="$HOME/.cache/atuin/init.zsh"
  if [[ ! -f "$_atuin_cache" || "${commands[atuin]}" -nt "$_atuin_cache" ]]; then
    mkdir -p "${_atuin_cache:h}"
    atuin init zsh --disable-up-arrow > "$_atuin_cache"
  fi
  source "$_atuin_cache"
  unset _atuin_cache
else
  zinit ice wait'0' lucid
  zinit load zdharma-continuum/history-search-multi-word
fi

# fzf 键位：只开 Ctrl+T（顶掉 emacs 的 transpose-chars，不用）。fzf 本体来自 brew；
# 原来的 `zinit light junegunn/fzf` 什么都没加载，已删。只截 key-bindings 段：fzf --zsh 后半段的
# completion.zsh 会 bindkey '^I' 抢走 fzf-tab 的 Tab。Ctrl+R 留给 hsmw；Alt+C 被 AeroSpace 占了，用 z。
# 太旧不支持 --zsh 的 fzf（服务器）→ 缓存为空 → 什么都不绑。
# fzf 配色：Catppuccin Latte（跟 kitty/tmux 一致）。fzf 不会探测背景，默认按暗色方案画，
# 亮底上 info/hl 发白、当前行是深灰条（2026-09-24）。base 用 light，只挑老版本 fzf 也认的键，
# 服务器上 fzf 旧一点也不会因未知颜色名直接拒绝启动。
export FZF_DEFAULT_OPTS="--color=light,fg:#4C4F69,fg+:#4C4F69,bg+:#CCD0DA,hl:#D20F39,hl+:#D20F39,info:#8839EF,prompt:#8839EF,pointer:#DC8A78,marker:#7287FD,spinner:#DC8A78,header:#D20F39,border:#9CA0B0"
if (( $+commands[fzf] )); then
  _fzf_cache="$HOME/.cache/fzf/key-bindings.zsh"
  if [[ ! -f "$_fzf_cache" || "${commands[fzf]}" -nt "$_fzf_cache" ]]; then
    mkdir -p "${_fzf_cache:h}"
    fzf --zsh 2>/dev/null | sed '/^### end: key-bindings.zsh ###$/q' > "$_fzf_cache"
  fi
  (( $+commands[fd] )) && FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --follow --exclude .git'
  FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && eza -1 --color=always {} || bat -n --color=always --line-range :200 {}'"
  FZF_CTRL_R_COMMAND= FZF_ALT_C_COMMAND= source "$_fzf_cache"
  unset _fzf_cache
fi

# zoxide 智能跳目录：init 脚本缓存，同 starship 写法。
# 原来的 zinit 写法（as"null" from"gh-r" sbin"zoxide"）缺 bin-gem-node annex，atload 从没跑过，
# z 一直是 rupa/z（zoxide db 停在 2025-12-03，2026-09-23 发现）。没装 zoxide 的机器退回 rupa/z。
if (( $+commands[zoxide] )); then
  _zoxide_cache="$HOME/.cache/zoxide/init.zsh"
  if [[ ! -f "$_zoxide_cache" || "${commands[zoxide]}" -nt "$_zoxide_cache" ]]; then
    mkdir -p "${_zoxide_cache:h}"
    zoxide init zsh > "$_zoxide_cache"
  fi
  source "$_zoxide_cache"
  unset _zoxide_cache
else
  zinit ice wait'0' lucid
  zinit light rupa/z
fi

# Git 补全
zinit ice wait'0' lucid blockf
zinit light zsh-users/zsh-completions

# Git 快捷别名
zinit ice wait'0' lucid
zinit snippet OMZ::lib/git.zsh
zinit ice wait'0' lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# 命令语法高亮：fast-syntax-highlighting（2026-09-24 从 zsh-users/zsh-syntax-highlighting 换过来）。
# 实测每敲一个键：300 字的长命令 17→9ms，粘贴 2.5k 字 187→71ms；日常短命令两边都是 1～2ms。
# 必须是 wait'0' 组最后一个（包住前面插件的 widget），顺带回放 zinit 截下的 compdef。
# 不再 zpcompinit —— 上面已经 compinit 过，那是第二次。
# 配色用内置主题，只改在 Catppuccin Latte 亮底上看不清的几项：蓝底 / 深蓝底(18) → 浅灰底，
# 变量的浅绿(113) → 紫；secondary 置空 —— 默认在 eval 之类的字符串里换成 free 主题，那套全是浅色字。
# 不用 fast-theme：它把主题写进 ~/.cache/fsh，是机器上的状态，不跟 dotfiles 走。
_fsh_latte() {
  local p=$FAST_THEME_NAME
  FAST_HIGHLIGHT_STYLES+=(
    ${p}paired-bracket   bg=#ccd0da
    ${p}global-alias     bg=#ccd0da
    ${p}case-condition   bg=#ccd0da
    ${p}subtle-bg        bg=#ccd0da
    ${p}here-string-text bg=#ccd0da
    ${p}here-string-var  fg=cyan,bg=#ccd0da
    ${p}variable         fg=#8839ef
    ${p}secondary        ''
  )
  unfunction _fsh_latte
}
zinit ice wait'0' lucid atinit"zicdreplay -q" atload"_fsh_latte"
zinit light zdharma-continuum/fast-syntax-highlighting

# Docker 插件
zinit ice wait'1' lucid
zinit snippet OMZ::plugins/docker/docker.plugin.zsh

# zsh-you-should-use
zinit ice wait'1' lucid
zinit light MichaelAquilina/zsh-you-should-use
ZSH_YOU_SHOULD_USE_EXCLUDE=('ls' 'cd')

# ----------------------- 自定义 ------------------------------

[ -f ~/.zsh/s3cmd/share-images.zsh ] && source ~/.zsh/s3cmd/share-images.zsh

# kitty tab 标题推送(本地 kitty 推 cwd/app/ssh;远端 ssh 会话推 user@host,
# 配合 ~/.config/kitty/tab_bar.py 与 kitty.conf 的 shell_integration no-title)
[ -f ~/.zsh/kitty-tab.zsh ] && source ~/.zsh/kitty-tab.zsh

# 长命令（≥15s）结束且 kitty 不在焦点时弹通知；tmux 里、kitty 直连的远端也能用（细节见文件头）
[ -f ~/.zsh/cmd-notify.zsh ] && source ~/.zsh/cmd-notify.zsh


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
setopt HIST_IGNORE_SPACE   # 行首加空格的命令不进历史（敲带密钥的命令时用）

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

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
# SSH_AUTH_SOCK（Bitwarden agent）已挪到 ~/.zshenv：.zshrc 只有交互式 shell 读，
# 脚本 / GUI 应用拿不到 agent，git 签名会报 "Couldn't get agent socket"。
