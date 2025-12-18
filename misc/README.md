# Misc 实用脚本集合

这个目录包含了各种实用的一键安装和配置脚本，用于快速部署常用工具和服务。

## 📦 脚本列表

### 1. Caddy Web 服务器

#### 基础版 - [`install_caddy.sh`](file:///Users/chy/workspace/mjj/local_config/misc/install_caddy.sh)

快速安装 Caddy Web 服务器的官方版本。

**特性：**
- ✅ 自动检测系统架构 (amd64, arm64, armv7, armv6)
- ✅ 从 GitHub Releases 下载最新版本
- ✅ 自动创建 systemd 服务
- ✅ 配置用户和目录结构
- ✅ 自动备份旧版本

**快速安装：**
```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/install_caddy.sh | sudo bash
```

**安装后配置：**
```bash
# 编辑配置文件
sudo nano /etc/caddy/Caddyfile

# 启动服务
sudo systemctl start caddy

# 查看状态
sudo systemctl status caddy
```

---

#### Cloudflare DNS 版 - [`install_cf_caddy.sh`](file:///Users/chy/workspace/mjj/local_config/misc/install_cf_caddy.sh)

使用 xcaddy 编译包含 Cloudflare DNS 挑战支持的 Caddy。适用于需要通配符证书或内网服务器的场景。

**特性：**
- ✅ 自动安装 Go 语言环境
- ✅ 使用 xcaddy 编译 Caddy
- ✅ 集成 Cloudflare DNS 模块
- ✅ 支持 DNS-01 挑战获取证书
- ✅ 创建环境变量配置文件

**快速安装：**
```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/install_cf_caddy.sh | sudo bash
```

**配置 Cloudflare：**
```bash
# 编辑环境变量文件
sudo nano /etc/caddy/caddy.env

# 添加你的 Cloudflare API Token
CLOUDFLARE_API_TOKEN=your_token_here
```

**Caddyfile 示例：**
```caddyfile
example.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy localhost:8080
}
```

---

### 2. Yazi 文件管理器 - [`yazi/`](file:///Users/chy/workspace/mjj/local_config/misc/yazi)

用 Rust 编写的快速终端文件管理器，支持异步 I/O。

**快速安装：**
```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/yazi/install_yazi.sh | sudo bash
```

详细文档请查看: [`yazi/README.md`](file:///Users/chy/workspace/mjj/local_config/misc/yazi/README.md)

---

### 3. SSH 增强工具 - [`install_tssh_trzsz.sh`](file:///Users/chy/workspace/mjj/local_config/misc/install_tssh_trzsz.sh)

一键安装 tssh 和 trzsz，增强 SSH 连接体验。

**包含工具：**
- **tssh**: 增强版 SSH 客户端，支持更多功能
- **trzsz**: 类似 rz/sz 的文件传输工具，支持断点续传

**快速安装：**
```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/install_tssh_trzsz.sh | sudo bash
```

**使用方法：**
```bash
# 使用 tssh 连接
tssh user@host

# 文件传输 (在 SSH 会话中)
trzsz upload /local/file
trzsz download /remote/file
```

**注意事项：**
- 使用 Ubuntu 的 trzsz PPA 源
- 适用于 Debian/Ubuntu 系统

---

### 4. Realm 端口转发 - [`realm.sh`](file:///Users/chy/workspace/mjj/local_config/misc/realm.sh)

功能强大的端口转发和流量中转工具，基于 Rust 开发。

**主要功能：**
- 🚀 高性能端口转发
- 📊 交互式菜单管理
- 🔄 支持 TCP/UDP 转发
- 📝 规则管理（增删改查）
- 🔧 Systemd 服务集成
- 📈 实时状态监控

**快速使用：**
```bash
# 交互式安装
sudo bash realm.sh

# 命令行添加规则（非交互式）
sudo bash realm.sh -l 0.0.0.0:8080 -r 192.168.1.100:80
```

**使用场景：**
- 端口转发和流量中转
- 内网穿透
- 负载均衡前置
- 多服务器流量分发

**菜单选项：**
1. 部署 Realm
2. 查看规则
3. 添加规则
4. 删除规则
5. 启动服务
6. 停止服务
7. 重启服务
8. 更新 Realm
9. 卸载 Realm
10. 更新脚本

**配置文件：** `/root/.realm/config.toml`

**示例配置：**
```toml
[network]
no_tcp = false  # 是否关闭 TCP 转发
use_udp = true  # 是否开启 UDP 转发

[[endpoints]]
listen = "0.0.0.0:8080"
remote = "192.168.1.100:80"

[[endpoints]]
listen = "0.0.0.0:3000"
remote = "10.0.0.5:3000"
```

---

## 🛠️ 通用使用说明

### 安装方式

所有脚本都支持以下三种安装方式：

#### 方式 1: 一键安装（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/cheny-00/local_config/main/misc/<script_name> | sudo bash
```

#### 方式 2: 下载后执行
```bash
wget https://raw.githubusercontent.com/cheny-00/local_config/main/misc/<script_name>
chmod +x <script_name>
sudo ./<script_name>
```

#### 方式 3: 克隆仓库
```bash
git clone https://github.com/cheny-00/local_config.git
cd local_config/misc
sudo ./<script_name>
```

### 环境变量

某些脚本支持通过环境变量自定义安装：

```bash
# Caddy 示例：指定版本
CADDY_VERSION=2.7.5 sudo -E ./install_caddy.sh

# Yazi 示例：指定版本
YAZI_VERSION=0.2.5 sudo -E ./yazi/install_yazi.sh
```

---

## 📋 系统要求

- **操作系统**: Debian 11+ / Ubuntu 20.04+
- **权限**: 所有脚本需要 root 权限（sudo）
- **依赖**: curl, wget, tar, systemctl（通常已预装）

---

## 🔧 故障排除

### 网络问题

如果下载失败，可能是网络连接问题：

```bash
# 使用代理
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# 或手动从 GitHub Releases 下载
```

### 权限问题

所有脚本都需要 root 权限：

```bash
# 使用 sudo 运行
sudo ./script.sh

# 或切换到 root 用户
su -
./script.sh
```

### Systemd 服务问题

查看服务状态和日志：

```bash
# 查看服务状态
systemctl status <service_name>

# 查看日志
journalctl -u <service_name> -f

# 重新加载配置
systemctl daemon-reload
systemctl restart <service_name>
```

---

## 📚 相关资源

### 官方文档
- [Caddy 文档](https://caddyserver.com/docs/)
- [Yazi 文档](https://yazi-rs.github.io/)
- [Realm GitHub](https://github.com/zhboner/realm)
- [trzsz GitHub](https://github.com/trzsz/trzsz)

### 社区支持
- [Caddy 社区](https://caddy.community/)
- [Yazi 讨论区](https://github.com/sxyazi/yazi/discussions)

---

## 📝 许可证

所有脚本采用 MIT 许可证，可自由使用和修改。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## ⚠️ 注意事项

1. **生产环境**: 建议先在测试环境验证后再部署到生产环境
2. **备份**: 脚本会自动备份旧版本，但建议手动备份重要配置
3. **防火墙**: 安装后记得配置防火墙规则开放相应端口
4. **安全性**: 请妥善保管 API Token 等敏感信息

---

**最后更新**: 2025-12-08
