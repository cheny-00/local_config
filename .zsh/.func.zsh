clip() {
  local data
  if [[ -f "$1" ]]; then
    data=$(< "$1")
  elif [ -t 0 ]; then
    data="$*"
  else
    data=$(cat)
  fi
  
  # Base64 编码
  local b64
  b64=$(printf "%s" "$data" | base64 | tr -d '\n')
  
  if [ -n "$TMUX" ]; then
    # tmux 环境：使用 DCS passthrough
    # 关键：直接用 printf 输出原始字节，不要用变量存储转义序列
    printf "\033Ptmux;\033\033]52;c;%s\007\033\\" "$b64"
  else
    # 非 tmux 环境
    printf "\033]52;c;%s\007" "$b64"
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

setp() {
    export http_proxy="http://127.0.0.1:31089"
    export https_proxy="http://127.0.0.1:31089"
    #export all_proxy="socks5://127.0.0.1:1080"   # 如果你有 socks5 入站，可以保留；没有可去掉
    echo "Proxy set on port 31089"
}

# 关闭代理
unsetp() {
    unset http_proxy
    unset https_proxy
    #unset all_proxy
    echo "Proxy removed"
}