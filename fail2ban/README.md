# Fail2ban Discord 通知 - 通用配置方案

基于 fail2ban 的入侵防御系统，集成 Discord webhook 通知，支持 IP 地理位置查询和代理。提供通用配置方案，方便扩展到任何服务。

## ✨ 特性

- 🚫 **自动封禁** - 检测并封禁恶意 IP
- 📢 **Discord 通知** - 实时推送封禁/解封通知
- 🌍 **IP 地理位置** - 显示国家、城市、ISP、旗帜 emoji
- 🔒 **代理支持** - 支持通过代理访问 Discord
- 🎨 **精美格式** - Discord embed 格式，详细信息展示
- 🔧 **通用方案** - 轻松扩展到任何服务
- 📦 **一键安装** - 自动化安装脚本

## 🚀 快速安装

### 一键安装

```bash
# 克隆仓库
git clone https://github.com/cheny-00/local_config.git
cd local_config/fail2ban

# 运行安装脚本
sudo bash install.sh
```

## ⚡ 快速开始 (Quick Start)

安装完成后，只需 3 步即可启用监控：

### 1. 获取 Discord Webhook URL

1. 打开 Discord 服务器设置
2. **集成** → **Webhook** → **新建 Webhook**
3. 复制 Webhook URL（格式：`https://discord.com/api/webhooks/...`）

### 2. 配置 SSH 保护（推荐）

```bash
# 创建 SSH 保护配置
sudo tee /etc/fail2ban/jail.d/sshd.conf > /dev/null << 'EOF'
[sshd]
enabled = true
port = ssh,22
filter = sshd
action = iptables-allports[name=sshd]
         discord-webhook[webhook_url="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"]
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# 将上面的 webhook_url 替换为你的实际 Webhook URL
```

### 3. 重启 fail2ban

```bash
sudo systemctl restart fail2ban

# 查看状态
sudo fail2ban-client status sshd
```

### 测试通知

```bash
# 测试封禁通知
/usr/local/bin/fail2ban-discord-notify ban "test-jail" "1.2.3.4" "3" "3600" "YOUR_WEBHOOK_URL"
```

✅ 完成！现在你会在 Discord 收到实时的入侵通知。

### 手动安装

<details>
<summary>点击展开手动安装步骤</summary>

#### 1. 安装依赖

```bash
# 安装 fail2ban
sudo apt update
sudo apt install fail2ban

# 安装 uv (Python 包管理器)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### 2. 创建 Python 项目

```bash
mkdir -p ~/workspace/fail2ban/fail2ban-discord
cd ~/workspace/fail2ban/fail2ban-discord

# 创建配置
cat > pyproject.toml << 'EOF'
[project]
name = "fail2ban-discord"
version = "1.0.0"
requires-python = ">=3.10"
dependencies = ["requests>=2.32.5"]
EOF

# 下载通知脚本
curl -o discord_notify.py https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/notify/discord_notify.py

# 初始化环境
uv sync
```

#### 3. 安装配置文件

```bash
# 安装 action
sudo curl -o /etc/fail2ban/action.d/discord-webhook.conf \
    https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/action.d/discord-webhook.conf

# 安装 filters
sudo curl -o /etc/fail2ban/filter.d/vaultwarden.conf \
    https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/filter.d/vaultwarden.conf
sudo curl -o /etc/fail2ban/filter.d/qbittorrent.conf \
    https://raw.githubusercontent.com/cheny-00/local_config/main/fail2ban/filter.d/qbittorrent.conf

# 创建包装脚本
sudo tee /usr/local/bin/fail2ban-discord-notify > /dev/null << 'EOF'
#!/bin/bash
cd ~/workspace/fail2ban/fail2ban-discord
exec ~/.local/bin/uv run discord_notify.py "$@"
EOF
sudo chmod +x /usr/local/bin/fail2ban-discord-notify
```

</details>

## 📝 配置服务

### 获取 Discord Webhook URL

1. 打开 Discord 服务器设置
2. 集成 → Webhook → 新建 Webhook
3. 复制 Webhook URL
4. 替换配置中的 `YOUR_DISCORD_WEBHOOK_URL`

### SSH 保护

```bash
sudo tee /etc/fail2ban/jail.d/sshd.conf > /dev/null << 'EOF'
[sshd]
enabled = true
port = ssh,22
filter = sshd
action = iptables-allports[name=sshd]
         discord-webhook[webhook_url="YOUR_DISCORD_WEBHOOK_URL"]
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

sudo systemctl restart fail2ban
```

### Vaultwarden (Bitwarden) 保护

```bash
sudo tee /etc/fail2ban/jail.d/vaultwarden.conf > /dev/null << 'EOF'
[vaultwarden]
enabled = true
port = 80,443
filter = vaultwarden
action = iptables-allports[name=vaultwarden]
         discord-webhook[webhook_url="YOUR_DISCORD_WEBHOOK_URL"]
logpath = /path/to/vaultwarden/data/vaultwarden.log
maxretry = 3
bantime = 14400
findtime = 14400
EOF

sudo systemctl restart fail2ban
```

### qBittorrent 保护

```bash
sudo tee /etc/fail2ban/jail.d/qbittorrent.conf > /dev/null << 'EOF'
[qbittorrent]
enabled = true
port = 8080
filter = qbittorrent
action = iptables-allports[name=qbittorrent]
         discord-webhook[webhook_url="YOUR_DISCORD_WEBHOOK_URL"]
logpath = /path/to/qbittorrent/logs/qbittorrent.log
maxretry = 3
bantime = 7200
findtime = 3600
EOF

sudo systemctl restart fail2ban
```

## 🔧 添加新服务（通用方法）

### 1. 创建 Filter

创建 `/etc/fail2ban/filter.d/your-service.conf`：

```ini
[INCLUDES]
before = common.conf

[Definition]
# 匹配失败日志的正则表达式
# <ADDR> 会被 fail2ban 替换为 IP 地址匹配模式
failregex = ^.*login failed.*IP: <ADDR>.*$
            ^.*authentication error.*from <ADDR>.*$

# 忽略特定模式（可选）
ignoreregex =
```

**正则表达式示例**：
- SSH: `^.*Failed password for .* from <ADDR>.*$`
- Web: `^.*401.*<ADDR>.*$`
- API: `^.*authentication failed.*<ADDR>.*$`

### 2. 创建 Jail

创建 `/etc/fail2ban/jail.d/your-service.conf`：

```ini
[your-service]
enabled = true
port = 8080,8443              # 服务端口
filter = your-service         # filter 名称（不含 .conf）
action = iptables-allports[name=your-service]
         discord-webhook[webhook_url="YOUR_DISCORD_WEBHOOK_URL"]
logpath = /path/to/service.log
maxretry = 5                  # 最大失败次数
bantime = 3600                # 封禁时长（秒）
findtime = 600                # 查找时间窗口（秒）
```

### 3. 测试 Filter

```bash
# 测试 filter 是否正确匹配日志
sudo fail2ban-regex /path/to/logfile /etc/fail2ban/filter.d/your-service.conf

# 查看匹配结果
sudo fail2ban-regex /path/to/logfile /etc/fail2ban/filter.d/your-service.conf --print-all-matched
```

### 4. 重启 Fail2ban

```bash
sudo systemctl restart fail2ban

# 查看状态
sudo fail2ban-client status
sudo fail2ban-client status your-service
```

## 📊 Discord 通知示例

### 封禁通知

```
🔴 IP Address Banned
An IP has been banned from jail sshd

🚫 Banned IP: 103.xxx.xxx.xxx
⚠️ Failed Attempts: 5
⏱️ Ban Duration: 1小时 (3600s)

📍 Location Information
🇨🇳 China
城市: Shanghai, Shanghai
ISP: China Telecom
组织: China Telecom Shanghai
AS: AS4134 CHINANET-BACKBONE
```

## ⚙️ 高级配置

### 配置代理

#### 方式 1: 配置文件（推荐）

如果需要通过代理访问 Discord：

```bash
sudo tee /etc/fail2ban/discord-proxy.conf > /dev/null << 'EOF'
# Discord webhook 代理配置
http_proxy = http://127.0.0.1:7890
EOF
```

**禁用代理**：删除配置文件或注释掉代理行

```bash
# 方法 1: 删除配置文件
sudo rm /etc/fail2ban/discord-proxy.conf

# 方法 2: 注释掉代理配置
sudo tee /etc/fail2ban/discord-proxy.conf > /dev/null << 'EOF'
# http_proxy = http://127.0.0.1:7890
EOF
```

#### 方式 2: 环境变量

也可以通过环境变量设置代理（优先级高于配置文件）：

```bash
# 在 /usr/local/bin/fail2ban-discord-notify 中添加
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
```

**注意**：
- 环境变量 `HTTP_PROXY`/`HTTPS_PROXY` 优先级最高
- 配置文件 `/etc/fail2ban/discord-proxy.conf` 次之
- 如果都不设置，则直连 Discord

**代理优先级**：环境变量 > 配置文件 > 不使用代理

### 参数说明

| 参数 | 说明 | 常用值 |
|------|------|--------|
| `enabled` | 是否启用 | `true` / `false` |
| `port` | 保护端口 | `22`, `80,443` |
| `filter` | 过滤器名称 | `sshd`, `vaultwarden` |
| `logpath` | 日志路径 | `/var/log/auth.log` |
| `maxretry` | 最大失败次数 | `3`, `5` |
| `bantime` | 封禁时长（秒） | `3600`(1h), `14400`(4h), `-1`(永久) |
| `findtime` | 查找窗口（秒） | `600`(10m), `3600`(1h) |

### 时长参考

- **10 分钟** = 600
- **1 小时** = 3600
- **4 小时** = 14400
- **1 天** = 86400
- **永久** = -1

## 🔍 常用命令

### 查看状态

```bash
# 所有 jail 状态
sudo fail2ban-client status

# 特定 jail 状态
sudo fail2ban-client status sshd

# 查看被封 IP
sudo fail2ban-client status sshd | grep "Banned IP"
```

### 手动封禁/解封

```bash
# 封禁 IP
sudo fail2ban-client set sshd banip 192.168.1.100

# 解封 IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# 解封所有 IP
sudo fail2ban-client unban --all
```

### 重载配置

```bash
# 重载所有配置
sudo fail2ban-client reload

# 重载特定 jail
sudo fail2ban-client reload sshd
```

### 测试通知

```bash
# 测试封禁通知
/usr/local/bin/fail2ban-discord-notify ban "test-jail" "1.2.3.4" "3" "3600" "YOUR_WEBHOOK_URL"

# 测试解封通知
/usr/local/bin/fail2ban-discord-notify unban "test-jail" "1.2.3.4" "YOUR_WEBHOOK_URL"
```

## 📁 文件结构

```
fail2ban/
├── README.md                        # 本文档
├── install.sh                       # 安装脚本
├── action.d/
│   └── discord-webhook.conf         # Discord 通知 action
├── filter.d/
│   ├── vaultwarden.conf             # Vaultwarden filter
│   └── qbittorrent.conf             # qBittorrent filter
├── examples/
│   ├── sshd.conf                    # SSH jail 示例
│   ├── vaultwarden.conf             # Vaultwarden jail 示例
│   └── qbittorrent.conf             # qBittorrent jail 示例
└── notify/
    └── discord_notify.py            # Discord 通知脚本
    # 未来支持:
    # ├── telegram_notify.py         # Telegram Bot 通知
    # └── bark_notify.py             # Bark 通知

安装后：
/etc/fail2ban/
├── action.d/discord-webhook.conf
├── filter.d/*.conf
├── jail.d/*.conf
├── discord-proxy.conf (可选)
└── examples/*.conf

/usr/local/bin/fail2ban-discord-notify
~/workspace/fail2ban/fail2ban-discord/
├── discord_notify.py
├── pyproject.toml
└── .venv/
```

## ❓ 故障排除

### 通知不工作

```bash
# 1. 检查脚本
/usr/local/bin/fail2ban-discord-notify ban "test" "1.2.3.4" "3" "3600" "YOUR_WEBHOOK"

# 2. 查看日志
sudo tail -f /var/log/fail2ban.log | grep discord

# 3. 检查 webhook URL
sudo grep webhook /etc/fail2ban/jail.d/*.conf
```

### Filter 不匹配

```bash
# 1. 查看实际日志格式
tail -50 /path/to/logfile

# 2. 测试 filter
sudo fail2ban-regex /path/to/logfile /etc/fail2ban/filter.d/your-filter.conf

# 3. 显示所有匹配
sudo fail2ban-regex /path/to/logfile /etc/fail2ban/filter.d/your-filter.conf --print-all-matched
```

### 服务无法启动

```bash
# 1. 检查配置语法
sudo fail2ban-client -t

# 2. 查看详细日志
sudo journalctl -u fail2ban -n 50

# 3. 检查配置文件权限
ls -la /etc/fail2ban/jail.d/
ls -la /etc/fail2ban/filter.d/
```

## 🔒 安全建议

1. **保护 Webhook URL** - 不要将包含 webhook 的配置提交到公共仓库
2. **合理设置参数** - 根据实际情况调整 maxretry 和 bantime
3. **定期审查** - 定期检查被封 IP 列表，避免误封
4. **白名单** - 为可信 IP 配置白名单（ignoreip）
5. **监控日志** - 定期查看 fail2ban 日志，确保正常运行

## 📚 更多资源

- [Fail2ban 官方文档](https://www.fail2ban.org/)
- [Fail2ban GitHub](https://github.com/fail2ban/fail2ban)
- [Discord Webhook API](https://discord.com/developers/docs/resources/webhook)
- [正则表达式测试](https://regex101.com/)

## 📄 许可

MIT License
