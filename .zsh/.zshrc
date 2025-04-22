
if [[ -n "$SSH_CONNECTION" && -z "$FASTFETCH_SHOWN" && $- == *i* ]]; then
  export FASTFETCH_SHOWN=1
  command -v fastfetch >/dev/null && fastfetch
fi

# ------------------ 基础环境变量 ------------------
export ZINIT_HOME="${HOME}/.zinit/bin"

if command -v nvim &>/dev/null; then
    export EDITOR=nvim
else
    export EDITOR=vim
fi
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PATH="$HOME/.local/bin:$PATH"


export TERM=xterm-256color
#export TERM=screen-256color

source $HOME/common_alias.zsh

# ------------------ 初始化  -------------------
# eval "$(starship init zsh)"
# eval "$(zoxide init zsh)"

# ------------------ 安装 Zinit（若未安装） ------------------
if [[ ! -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  mkdir -p ~/.zinit
  git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi

# 只在交互式 Shell 加载插件
[[ -o interactive ]] && source "${ZINIT_HOME}/zinit.zsh"

# ------------------ 插件加载（Turbo Mode） ------------------

# 自动建议（右侧灰字）
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# 命令语法高亮
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

# 历史模糊搜索（↑支持多词）
zinit ice wait lucid
zinit load zdharma/history-search-multi-word

# fzf 补全增强
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# fzf 本体支持（Ctrl-R、文件搜索等）
zinit ice wait lucid
zinit light junegunn/fzf
[[ ! "$PATH" == *$HOME/.fzf/bin* ]] && export PATH="$HOME/.fzf/bin:$PATH"

# z：跳目录工具
zinit ice wait lucid
zinit light rupa/z

# Git 补全
zinit ice wait lucid
zinit light zsh-users/zsh-completions

# Git 快捷别名（gst, gco, glg 等）
zinit ice wait lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Docker 插件（如 dps, dcu 等别名）
zinit ice wait lucid
zinit snippet OMZ::plugins/docker/docker.plugin.zsh

# ------------------ 补全系统 ------------------
autoload -Uz compinit && compinit

# ------------------ Zsh 优化行为 ------------------
setopt AUTO_CD                # 自动进入目录
setopt HIST_IGNORE_ALL_DUPS  # 去重历史
setopt SHARE_HISTORY         # 多终端共享历史
HISTFILE=~/.zsh_history        # 历史文件路径
HISTSIZE=10000                 # 内存中历史条目数
SAVEHIST=10000                 # 写入文件的条目数

# 启用共享和立即写入
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS


# pyenv
if command -v pyenv &>/dev/null; then
    zinit ice wait lucid
    zinit snippet OMZ::plugins/pyenv/pyenv.plugin.zsh
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - zsh)"
fi


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

