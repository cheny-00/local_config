# Tmux 配置

tmux 的完整配置方案，包含插件管理器和常用插件。

## ✨ 特性

- 🎨 **现代化主题** - 精美的状态栏和配色方案
- 🔌 **插件管理** - 使用 TPM (Tmux Plugin Manager)
- ⌨️ **合理快捷键** - 优化的快捷键绑定
- 🔧 **开箱即用** - 一键安装所有配置

## 🚀 快速安装

### 方式一：独立安装（推荐）

```bash
# 直接运行安装脚本
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/tmux/tmux_setup.sh)

# 或者克隆仓库后安装
git clone https://github.com/cheny-00/local_config.git
cd local_config/tmux
bash tmux_setup.sh
```

### 方式二：作为完整配置的一部分

如果你使用主安装脚本，可以在安装时选择配置 tmux：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh) -t
```

## 📋 前置要求

- **tmux** 已安装
- **git** 已安装（用于安装 TPM 和插件）

### 安装 tmux

```bash
# Ubuntu/Debian
sudo apt install tmux git

# CentOS/RHEL
sudo yum install tmux git

# macOS
brew install tmux git
```

## 🛠️ 功能说明

### 自动安装内容

1. **TPM (Tmux Plugin Manager)** - 插件管理器
2. **.tmux.conf** - tmux 配置文件
3. **插件自动安装** - 配置中的所有插件

### 配置文件位置

- `~/.tmux.conf` - 主配置文件
- `~/.tmux/plugins/tpm` - TPM 插件管理器
- `~/.tmux/plugins/*` - 已安装的插件

## 📝 配置文件详解

### 基本设置

```bash
# 修改前缀键为 Ctrl+a（可选）
# 默认是 Ctrl+b

# 启用鼠标支持
set -g mouse on

# 256 色支持
set -g default-terminal "screen-256color"
```

### 常用快捷键

#### 基本操作

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+b %` | 垂直分割窗格 |
| `Ctrl+b "` | 水平分割窗格 |
| `Ctrl+b 方向键` | 切换窗格 |
| `Ctrl+b c` | 创建新窗口 |
| `Ctrl+b n` | 下一个窗口 |
| `Ctrl+b p` | 上一个窗口 |
| `Ctrl+b d` | 分离会话 |
| `Ctrl+b [` | 进入复制模式 |

#### 插件管理（TPM）

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+b I` | 安装插件（大写 I） |
| `Ctrl+b U` | 更新插件（大写 U） |
| `Ctrl+b alt+u` | 卸载插件 |

## 🔌 插件列表

配置文件中包含的常用插件（根据实际 .tmux.conf 内容）：

- **tmux-plugins/tpm** - 插件管理器
- **tmux-plugins/tmux-sensible** - 基础优化配置
- **tmux-plugins/tmux-resurrect** - 会话保存/恢复
- **tmux-plugins/tmux-continuum** - 自动保存会话

## 📖 使用指南

### 首次使用

安装完成后：

```bash
# 1. 启动 tmux
tmux

# 2. 如果配置未生效，手动重载
# 在 tmux 内按 Ctrl+b，然后输入：
:source-file ~/.tmux.conf

# 3. 安装插件（如果自动安装失败）
# 在 tmux 内按 Ctrl+b，然后按 I（大写）
```

### 会话管理

```bash
# 创建新会话
tmux new -s session_name

# 列出所有会话
tmux ls

# 附加到会话
tmux attach -t session_name
# 或简写
tmux a -t session_name

# 分离当前会话
# 在 tmux 内按 Ctrl+b d

# 删除会话
tmux kill-session -t session_name
```

### 窗口和窗格

```bash
# 创建新窗口
Ctrl+b c

# 重命名当前窗口
Ctrl+b ,

# 分割窗格（垂直）
Ctrl+b %

# 分割窗格（水平）
Ctrl+b "

# 关闭窗格
Ctrl+b x
# 或直接在窗格中输入
exit
```

## 🔧 自定义配置

### 修改配置文件

```bash
# 编辑配置
vim ~/.tmux.conf

# 在 tmux 内重载配置
Ctrl+b :source-file ~/.tmux.conf
```

### 常用自定义

#### 修改前缀键

```bash
# 取消默认前缀键
unbind C-b
# 设置新的前缀键为 Ctrl+a
set -g prefix C-a
bind C-a send-prefix
```

#### 添加新插件

在 `~/.tmux.conf` 中添加：

```bash
# 添加插件
set -g @plugin 'tmux-plugins/tmux-yank'

# 重载配置并安装
# Ctrl+b :source-file ~/.tmux.conf
# Ctrl+b I（安装新插件）
```

## ❓ 故障排除

### 插件未安装

```bash
# 手动安装 TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 在 tmux 内安装插件
# Ctrl+b I
```

### 显示问题

```bash
# 确保终端支持 256 色
echo $TERM  # 应该显示包含 256color

# 重启 tmux server
tmux kill-server
tmux
```

### 配置不生效

```bash
# 1. 检查配置文件语法
tmux source ~/.tmux.conf

# 2. 查看 tmux 日志
# 在 tmux 内按 Ctrl+b :
# 然后输入: show-messages

# 3. 完全重启 tmux
tmux kill-server
tmux
```

### 鼠标不工作

确保配置文件中有：

```bash
set -g mouse on
```

然后重载配置：

```bash
# 在 tmux 内
Ctrl+b :source-file ~/.tmux.conf
```

## 🎨 主题定制

如果想使用其他主题，可以添加主题插件：

```bash
# 在 ~/.tmux.conf 中添加
set -g @plugin 'dracula/tmux'
# 或
set -g @plugin 'catppuccin/tmux'

# 然后安装
# Ctrl+b I
```

## 📚 更多资源

- [Tmux 官方文档](https://github.com/tmux/tmux/wiki)
- [TPM 插件列表](https://github.com/tmux-plugins/list)
- [Tmux 速查表](https://tmuxcheatsheet.com/)

## 🆘 获取帮助

- 查看 tmux 手册：`man tmux`
- 在 tmux 内查看所有快捷键：`Ctrl+b ?`
- 查看所有命令：`tmux list-commands`

## 📄 许可

MIT License
