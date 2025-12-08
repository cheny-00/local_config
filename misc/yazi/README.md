# Yazi 一键安装脚本

[Yazi](https://github.com/sxyazi/yazi) 是一个用 Rust 编写的快速终端文件管理器，支持异步 I/O，适用于 Debian 13。

## 快速安装

### 方法 1: 使用 curl (推荐)

```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/yazi/install_yazi.sh | sudo bash
```

### 方法 2: 下载后执行

```bash
# 下载脚本
wget https://raw.githubusercontent.com/cheny-00/local_config/main/misc/yazi/install_yazi.sh

# 添加执行权限
chmod +x install_yazi.sh

# 运行安装
sudo ./install_yazi.sh
```

### 方法 3: 克隆仓库后安装

```bash
# 克隆仓库
git clone https://github.com/cheny-00/local_config.git

# 进入目录
cd local_config/misc

# 运行安装脚本
sudo ./install_yazi.sh
```

## 功能特性

- ✅ 自动检测系统架构 (x86_64, aarch64)
- ✅ 自动获取最新版本
- ✅ 从 GitHub Releases 下载官方预编译二进制文件
- ✅ 自动备份已存在的旧版本
- ✅ 安装 `yazi` 和 `ya` 两个命令行工具
- ✅ 完整的错误处理和状态提示

## 系统要求

- **操作系统**: Debian 13 (或其他 Linux 发行版)
- **架构**: x86_64 或 aarch64 (ARM64)
- **权限**: 需要 root 权限 (sudo)
- **依赖**: curl, unzip (脚本会自动安装 unzip)

## 安装后配置

### 基本使用

```bash
# 启动 Yazi
yazi

# 在指定目录启动
yazi /path/to/directory

# 查看帮助
yazi --help
```

### 键盘快捷键 (部分)

- `q` - 退出
- `j/k` 或 `↑/↓` - 上下移动
- `h/l` 或 `←/→` - 进入/退出目录
- `Space` - 选中文件
- `Enter` - 打开文件
- `y` - 复制
- `x` - 剪切
- `p` - 粘贴
- `d` - 删除
- `/` - 搜索

### 可选依赖 (增强功能)

为了获得最佳体验，建议安装以下可选依赖：

```bash
# 文件预览支持
sudo apt install -y ffmpegthumbnailer fd-find ripgrep fzf zoxide imagemagick poppler-utils

# 压缩文件预览
sudo apt install -y jq p7zip-full unrar

# 额外工具
sudo apt install -y bat eza
```

### 配置文件

Yazi 的配置文件位于 `~/.config/yazi/`，你可以自定义：

```bash
# 创建配置目录
mkdir -p ~/.config/yazi

# 编辑配置（首次运行会自动创建）
yazi
```

可以参考[官方文档](https://yazi-rs.github.io/docs/configuration/overview)进行配置。

## 环境变量

可以通过环境变量自定义安装：

```bash
# 安装特定版本
YAZI_VERSION=0.2.5 sudo -E ./install_yazi.sh
```

## 卸载

如果需要卸载 Yazi：

```bash
sudo rm -f /usr/local/bin/yazi /usr/local/bin/ya
rm -rf ~/.config/yazi
```

## 故障排除

### 无法下载

如果下载失败，可能是网络问题：
- 检查网络连接
- 尝试使用代理
- 手动从 [GitHub Releases](https://github.com/sxyazi/yazi/releases) 下载

### 架构不支持

当前脚本支持 x86_64 和 aarch64 架构。如果你使用其他架构，需要：
- 查看是否有对应架构的预编译版本
- 考虑从源码编译安装

### 权限问题

脚本需要 root 权限安装到 `/usr/local/bin`，如果不想使用 sudo：
- 可以修改 `INSTALL_DIR` 变量到用户目录
- 例如：`INSTALL_DIR="$HOME/.local/bin"`

## 更多资源

- 📖 [官方文档](https://yazi-rs.github.io/)
- 💻 [GitHub 仓库](https://github.com/sxyazi/yazi)
- 🎨 [插件列表](https://yazi-rs.github.io/docs/plugins/overview)
- 💬 [社区讨论](https://github.com/sxyazi/yazi/discussions)

## 许可证

Yazi 采用 MIT 许可证。本安装脚本同样采用 MIT 许可证。
