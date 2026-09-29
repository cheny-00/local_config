# ============================================================
# GENERATED FILE - DO NOT EDIT
# 源: 私有 chezmoi dotfiles 仓库的 linux 渲染，手改必被覆盖
# 更新: 在 Mac 上运行 dotfiles 仓库的 .scripts/sync-server-configs.sh
# ============================================================


clip() {
  local data

  if [[ -f "$1" ]]; then
    data=$(< "$1")
  elif [ -t 0 ]; then
    data="$*"
  else
    data=$(cat)
  fi

  local osc
  osc="\033]52;c;$(printf "%s" "$data" | base64 | tr -d '\n')\a"

  # Send using echo -ne to ensure escape codes work
  if [ -n "$TMUX" ]; then
    # Send through tmux passthrough
    printf "\033Ptmux;\033%s\033\\" "$osc"
  else
    # echo -ne ensures it gets interpreted
    echo -ne "$osc"
  fi
}

sshclip() {
  # 参数检查：确保正好传入两个参数
  if [ $# -ne 2 ]; then
    echo "用法：sshclip <ssh-host> <remote-file-path>"
    return 1
  fi

  # 第一个参数：SSH 主机（可以是 ~/.ssh/config 中的别名，或 user@host）
  local host="$1"
  # 第二个参数：远端文件路径（可用绝对路径或 ~）
  local remote_path="$2"

  # 核心命令：
  #  1. ssh "$host" "cat '$remote_path'" —— 在远端执行 cat，把文件内容输出到 stdout
  #  2. | pbcopy                          —— 管道传输到本地 pbcopy，复制到系统剪贴板
  ssh "$host" "cat '$remote_path'" | pbcopy

  # 检查上一步命令是否执行成功
  if [ $? -eq 0 ]; then
    echo "✅ 已从 ${host}:${remote_path} 复制到剪贴板"
  else
    echo "❌ 复制失败，请检查 SSH 连接或远端文件路径是否正确"
    return 1
  fi
}

# yazi 包装器：退出时让 shell 跟着 cd 到 yazi 里最后停留的目录。
#
# 为什么需要它：yazi 是 shell fork 出的子进程，子进程改不了父进程的 cwd
#（Unix 没有这种 syscall，也不该有）。所以约定俗成的绕法是：
#   子进程把最终目录写进临时文件 → 父 shell 里的函数读出来，自己 cd。
# 必须是「函数」而不是脚本 —— 脚本又是一个子进程，它的 cd 同样会随进程蒸发。
#（zoxide 的 z 是同一个道理。）
#
# 用法：敲 y 代替 yazi。退出时 q = 带我走，Q = 只看看别动我。
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
  # --cwd-file：yazi 官方留的钩子，退出时把 cwd 投进这个「信箱」
  yazi "$@" --cwd-file="$tmp"
  # -d '' 而非按行读：路径可能含空格/换行，用 NUL 作分隔才安全
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

