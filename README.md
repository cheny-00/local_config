# Local Config - Dotfiles 一键安装

自动化配置 VPS/服务器开发环境的工具集，包含 vim、zsh、starship、eza、fzf、zoxide 等现代化命令行工具。

## ✨ 特性

- 🚀 **一键安装** - 单条命令完成所有配置
- 👤 **智能用户管理** - 自动检测/创建用户，自动复制 SSH 密钥
- 🎨 **精美主题** - Starship nerd-font-symbols 主题
- 📝 **完整配置** - vim、zsh、tmux 全套配置
- 🔧 **开箱即用** - 安装即可使用，无需手动配置
- 🖥️ **主机名管理** - 自动设置主机名并更新 /etc/hosts
- ⚙️ **灵活参数** - 支持 GNU 风格命令行选项

## 🚀 快速开始

### 显示帮助信息

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh) --help
```

### 一键安装

```bash
# 交互式安装（会询问所有配置选项）
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh)

# 指定用户名
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh) -u chy

# 指定用户名和主机名
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh) -u chy -h my-server

# 完整配置（用户名、主机名、SSH 安全、tmux）
bash <(curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/init.sh) -u chy -h my-server -k -t
```

### 命令行选项

| 选项 | 长选项 | 说明 |
|------|--------|------|
| `-u NAME` | `--user NAME` | 指定用户名（默认交互式询问） |
| `-h NAME` | `--hostname NAME` | 指定主机名（默认不修改） |
| `-k` | `--ssh-key` | 配置 SSH 安全 |
| `-t` | `--tmux` | 配置 tmux |
| | `--help` | 显示帮助信息 |

### 功能清单

#### 🛠️ 工具安装
- ✅ **vim** - 经典文本编辑器 + vim-plug 插件管理
- ✅ **zsh** - 强大的 shell + zinit 插件管理
- ✅ **starship** - 快速、可定制的命令行提示符
- ✅ **eza** - 现代化 ls 替代品（带图标）
- ✅ **fzf** - 模糊搜索工具
- ✅ **zoxide** - 智能目录跳转
- ✅ **tssh** - 增强的 SSH 客户端
- ✅ **trzsz** - 支持 tmux 的文件传输工具

#### 📦 基础工具
- ✅ **系统工具**: curl, wget, git, tmux, htop, rsync
- ✅ **网络工具**: iperf3, mtr
- ✅ **数据处理**: jq, yq
- ✅ **压缩工具**: zip, gzip, bzip2, xz-utils
- ✅ **开发工具**: build-essential

#### 📁 配置文件
- ✅ `~/.zshrc` - zsh 主配置（通用别名已内联）
- ✅ `~/.func.zsh` - 自定义函数
- ✅ `~/.vimrc` - vim 完整配置
- ✅ `~/.vim/` - vim 插件和临时文件目录
- ✅ `~/.config/starship.toml` - starship 配置
- ℹ️ 以上配置来自本仓库 `config/`，该目录是**生成物**（私有 chezmoi
  dotfiles 仓库的 linux 渲染），请勿直接修改

#### 🎨 Vim 特性
- 主题：PaperColor, Tokyo Night, Gruvbox, Molokai, Catppuccin 等
- 插件：NERDTree, Airline, vim-visual-multi, rainbow, 等
- 自动创建备份/undo/swap 目录
- vim-plug 自动安装

## 安装内容

### Shell 环境
- **zsh**: 强大的 shell
- **zinit**: 快速的 zsh 插件管理器
- **插件**:
  - zsh-syntax-highlighting (语法高亮)
  - zsh-autosuggestions (命令建议)
  - fzf-tab (模糊补全)
  - history-search-multi-word (历史搜索)

### 现代化工具
- **starship**: 快速、可定制的命令行提示符
- **eza**: 带图标的 ls 替代品
- **fzf**: 模糊搜索工具
- **zoxide**: 智能目录跳转 (z 命令)
- **tssh**: 增强的 SSH 客户端，支持更多特性
- **trzsz**: 支持 tmux 的文件传输工具 (类似 rz/sz)

### 配置文件
- `~/.zshrc` / `~/.func.zsh` / `~/.vimrc` / `~/.tmux.conf`: 来自本仓库 `config/`
  （生成物，源头是私有 chezmoi dotfiles 仓库，勿手改）
- `~/.config/starship.toml`: starship 配置（安装时生成）

## 使用示例

### 安装后使用

```bash
# 切换到新用户
su - username

# 或者重启 shell
exec zsh
```

### 常用别名

```bash
# 目录导航
ll       # 详细列表
la       # 显示隐藏文件
lt       # 按时间排序
tree     # 树状结构

# Docker
dps      # docker ps
dco      # docker compose
dcu      # docker compose up
dcd      # docker compose down

# Tmux
ta       # tmux attach
tn       # tmux new-session
```

### 智能工具

```bash
# zoxide - 智能跳转
z <关键词>   # 跳转到匹配的目录

# fzf - 模糊搜索
Ctrl+R      # 搜索历史命令
**<TAB>     # 模糊文件搜索
```

## 支持的系统

- Ubuntu 18.04+
- Debian 10+
- 其他基于 Debian 的发行版

## 📂 目录结构

```
local_config/
├── init.sh                      # 🚀 一键安装脚本
├── config/                      # ⚠️ 生成物，勿手改（源: 私有 chezmoi 仓库）
│   ├── .zshrc                  # zsh 主配置（linux 渲染，含通用别名）
│   ├── .tmux.conf              # tmux 配置（linux 渲染）
│   ├── .vimrc                  # vim 配置
│   └── .func.zsh               # 自定义函数
├── tmux/
│   └── tmux_setup.sh           # tmux 安装脚本
├── ssh/
│   └── ssh_security.sh         # SSH 安全加固
├── fail2ban/                    # fail2ban 配置
│   ├── jail.local
│   └── action.d/
│       └── discord.conf
└── misc/
    ├── realm.sh                # Realm 转发工具
    └── install_tssh_trzsz.sh   # tssh 和 trzsz 安装脚本

config/ 的更新方式: 在 Mac 上改私有 chezmoi 仓库后
运行其 .scripts/sync-server-configs.sh，再提交本仓库。
```

### 安装后的用户目录结构

```
~/
├── .vimrc                      # vim 配置
├── .vim/
│   ├── autoload/
│   │   └── plug.vim           # vim-plug 插件管理器
│   ├── plugged/               # vim 插件目录
│   └── files/
│       ├── backup/            # 备份文件
│       ├── undo/              # undo 历史
│       ├── swap/              # swap 文件
│       └── info/              # viminfo
├── .zshrc                      # zsh 配置（chezmoi）
├── .alias.zsh                  # 别名（chezmoi）
├── .func.zsh                   # 函数（chezmoi）
├── .config/
│   └── starship.toml          # starship 配置
├── .fzf/                      # fzf 安装目录
└── .cache/
    └── zsh/                   # zsh 缓存
```

## 🛠️ Vim 使用指南

### 首次使用

安装完成后，首次打开 vim 需要安装插件：

```bash
# 打开 vim
vim

# 在 vim 中运行（输入以下命令）
:PlugInstall
```

等待插件安装完成后即可使用。

### Vim 快捷键

#### 基本操作
- `<Space>` - Leader 键
- `<Leader><Space>` - 取消搜索高亮
- `<Leader>ms` - 保存会话
- `<Leader>ev` - 编辑 .vimrc（垂直分屏）
- `<Leader>sv` - 重新加载 .vimrc
- `<Leader>\` - 打开终端（标签页）
- `<Leader>e` - 多行编辑到结尾列

#### 文件浏览
- `F2` - 打开/关闭 NERDTree 文件树
- NERDTree 中按 `m` 可以创建、删除、移动文件

#### 主题切换

默认使用 PaperColor（亮色）主题，可以在 .vimrc 中修改：

```vim
" 切换到其他主题（取消注释相应行）
" colorscheme tokyonight
" colorscheme gruvbox
" colorscheme catppuccin_mocha
" colorscheme molokai

" 切换背景（深色/浅色）
set background=dark   " 或 light
```

## 📝 手动安装

如果需要手动安装，可以分步执行：

```bash
# 1. 安装基础依赖
sudo apt update
sudo apt install -y curl wget git gpg unzip zsh sudo \
    build-essential vim tmux htop \
    iperf3 mtr-tiny jq yq \
    zip gzip bzip2 xz-utils rsync \
    ca-certificates

# 2. 安装 eza
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# 3. 安装 fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# 4. 安装 zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# 5. 安装 starship
curl -sS https://starship.rs/install.sh | sh

# 6. 创建配置目录
mkdir -p ~/.config
mkdir -p ~/.vim/files/{backup,undo,info,swap}
mkdir -p ~/.vim/{autoload,plugged}

# 7. 配置 starship 主题
starship preset nerd-font-symbols -o ~/.config/starship.toml

# 8. 下载配置文件（config/ 为生成物，源: 私有 chezmoi 仓库）
wget -O ~/.zshrc https://raw.githubusercontent.com/cheny-00/local_config/main/config/.zshrc
wget -O ~/.func.zsh https://raw.githubusercontent.com/cheny-00/local_config/main/config/.func.zsh
wget -O ~/.vimrc https://raw.githubusercontent.com/cheny-00/local_config/main/config/.vimrc
wget -O ~/.tmux.conf https://raw.githubusercontent.com/cheny-00/local_config/main/config/.tmux.conf

# 9. 安装 vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 10. 设置默认 shell
chsh -s $(which zsh)

# 11. 重启 shell
exec zsh

# 12. 打开 vim 安装插件
vim +PlugInstall +qall
```

## ❓ 故障排除

### zsh 插件未加载
首次启动 zsh 时，zinit 会自动安装插件，这可能需要几秒钟。如果遇到问题：

```bash
# 手动安装 zinit
rm -rf ~/.zinit
git clone https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
```

### vim 插件未安装
如果 vim 插件未自动安装：

```bash
# 手动安装插件
vim +PlugInstall +qall

# 或在 vim 中执行
:PlugInstall
```

### starship 不显示图标
确保终端使用了 Nerd Font 字体。推荐字体：
- **FiraCode Nerd Font** (推荐)
- **JetBrainsMono Nerd Font**
- **Meslo Nerd Font**

下载地址：https://www.nerdfonts.com/

### vim 主题显示异常
如果 vim 颜色显示不正常，检查终端是否支持真彩色：

```bash
# 在 .zshrc 或 .bashrc 中添加
export TERM=xterm-256color
```

### 权限问题
如果遇到权限问题，检查文件所有者：

```bash
# 修复主目录权限
sudo chown -R $USER:$USER ~
```

### fzf 快捷键不工作
确保 fzf 正确初始化：

```bash
# 检查 .zshrc 中是否有以下内容
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
```

## 📸 截图

安装后的效果（需要终端使用 Nerd Font 字体）：

### Starship 提示符
- 显示 git 分支和状态
- 显示当前目录
- 彩色图标和符号

### Vim 编辑器
- NERDTree 文件树
- Airline 状态栏
- 语法高亮和主题

### Zsh 功能
- 语法高亮（正确的命令绿色，错误红色）
- 自动建议（灰色）
- 智能补全（Tab 键）

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 如何贡献

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📜 更新日志

### v3.0 (2025-01-30)
- ✨ 添加 GNU 风格命令行选项支持（`--help`, `-u`, `-h`, `-k`, `-t`）
- ✨ 添加主机名设置功能，自动更新 /etc/hosts
- ✨ 自动复制 SSH 密钥到新用户（追加模式）
- 🐛 修复 zoxide 安装路径问题
- 🐛 修复非交互式运行时的 read 命令问题
- 🐛 修复 sudo 主机名解析警告
- 📝 添加完整的帮助文档和使用示例
- ⚠️ **破坏性变更**: 旧的位置参数格式不再支持

### v2.0 (2025-01-20)
- ✨ 添加 vim 完整配置和插件管理
- ✨ 自动创建 vim 目录结构
- ✨ 添加 vim-plug 和常用插件
- 📝 更新文档，添加 vim 使用指南
- 🔧 优化安装脚本结构

### v1.0
- ✨ 初始版本
- ✨ 支持 zsh、starship、eza、fzf、zoxide 安装
- 👤 用户管理功能

## 📄 许可

MIT License

## 🙏 致谢

感谢以下开源项目：
- [vim-plug](https://github.com/junegunn/vim-plug)
- [starship](https://starship.rs/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [eza](https://github.com/eza-community/eza)
- [fzf](https://github.com/junegunn/fzf)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- All vim plugin authors
