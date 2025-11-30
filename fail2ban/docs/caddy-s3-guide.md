# Caddy + SeaweedFS S3 Fail2ban 保护指南

## 📋 概述

本指南介绍如何使用 fail2ban 保护 Caddy 反向代理的 SeaweedFS S3 服务，防止：
- 🔴 S3 密钥暴力破解
- 🔴 恶意扫描和探测
- 🔴 异常 API 调用
- 🔴 DDoS 前期探测

## 🎯 推荐方案

### 方案对比

| 方案 | 监控对象 | 优点 | 缺点 | 推荐度 |
|------|---------|------|------|--------|
| **Caddy 日志** | HTTP 访问日志 | 统一入口，格式可控 | 需要配置 Caddy 日志 | ⭐⭐⭐⭐⭐ |
| **SeaweedFS 日志** | S3 应用日志 | 更精确的 S3 错误 | 日志格式可能变化 | ⭐⭐⭐ |
| **双重保护** | 两者都监控 | 最全面的保护 | 配置复杂 | ⭐⭐⭐⭐ |

**推荐：** 使用 **Caddy 日志方案**（方案 1）

## 🚀 快速部署（Caddy 日志方案）

### 1. 配置 Caddy 日志

编辑你的 Caddyfile：

```caddyfile
# 方式 1: JSON 格式（推荐）
s3.example.com {
    log {
        output file /var/log/caddy/s3-access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }

    reverse_proxy localhost:8333 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
    }
}

# 方式 2: Common Log 格式
s3.example.com {
    log {
        output file /var/log/caddy/s3-access.log
        format single_field common_log "{remote_ip} - {user_id} [{time}] \"{method} {uri} {proto}\" {status} {size}"
    }

    reverse_proxy localhost:8333
}
```

### 2. 创建日志目录并重载 Caddy

```bash
# 创建日志目录
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy

# 测试配置
caddy validate --config /etc/caddy/Caddyfile

# 重载配置
sudo systemctl reload caddy
```

### 3. 安装 fail2ban 配置

```bash
# 安装 filter
sudo cp filter.d/caddy-s3.conf /etc/fail2ban/filter.d/

# 配置 jail
sudo tee /etc/fail2ban/jail.d/caddy-s3.conf > /dev/null << 'EOF'
[caddy-s3]
enabled = true
port = http,https
filter = caddy-s3
action = iptables-allports[name=caddy-s3]
         discord-webhook[webhook_url="YOUR_DISCORD_WEBHOOK_URL"]
logpath = /var/log/caddy/s3-access.log
maxretry = 3
bantime = 14400
findtime = 3600
EOF

# 重启 fail2ban
sudo systemctl restart fail2ban
```

### 4. 测试配置

```bash
# 测试 filter 是否匹配日志
sudo fail2ban-regex /var/log/caddy/s3-access.log /etc/fail2ban/filter.d/caddy-s3.conf

# 查看 jail 状态
sudo fail2ban-client status caddy-s3
```

## 🧪 测试方法

### 生成测试日志

**JSON 格式测试：**

```bash
# 模拟 403 错误（认证失败）
echo '{"level":"info","ts":1234567890,"remote_ip":"1.2.3.4","method":"GET","uri":"/bucket/file","status":403}' >> /var/log/caddy/s3-access.log

# 测试 filter
sudo fail2ban-regex /var/log/caddy/s3-access.log /etc/fail2ban/filter.d/caddy-s3.conf --print-all-matched
```

**Common Log 格式测试：**

```bash
# 模拟 401 错误
echo '1.2.3.4 - - [01/Dec/2024:12:00:00 +0800] "GET /bucket/file HTTP/1.1" 401 1234' >> /var/log/caddy/s3-access.log

# 测试 filter
sudo fail2ban-regex /var/log/caddy/s3-access.log /etc/fail2ban/filter.d/caddy-s3.conf
```

### 真实环境测试

使用 s3cmd 或 aws-cli 故意发送错误的密钥：

```bash
# 配置错误的密钥
export AWS_ACCESS_KEY_ID="wrong_key"
export AWS_SECRET_ACCESS_KEY="wrong_secret"

# 尝试访问（会触发 403）
aws s3 ls s3://your-bucket --endpoint-url https://s3.example.com

# 查看是否被封禁
sudo fail2ban-client status caddy-s3
```

## 📊 监控建议

### 1. 监控封禁情况

```bash
# 实时监控日志
sudo tail -f /var/log/fail2ban.log | grep caddy-s3

# 查看被封 IP
sudo fail2ban-client get caddy-s3 banned
```

### 2. Discord 通知配置

fail2ban 会自动发送 Discord 通知，包含：
- 🚫 被封 IP 地址
- 🌍 IP 地理位置（国家、城市、ISP）
- ⚠️ 失败次数
- ⏱️ 封禁时长

### 3. 定期审查

```bash
# 每周查看统计
sudo fail2ban-client status caddy-s3

# 查看日志中的异常模式
sudo grep -E '40[13]' /var/log/caddy/s3-access.log | tail -50
```

## ⚙️ 参数调优

### 严格程度建议

**公网 S3（推荐严格）：**
```ini
maxretry = 2       # 2 次失败即封
bantime = 28800    # 封禁 8 小时
findtime = 3600    # 1 小时窗口
```

**内网 S3（宽松）：**
```ini
maxretry = 5       # 5 次失败
bantime = 3600     # 封禁 1 小时
findtime = 1800    # 30 分钟窗口
```

**测试环境（非常宽松）：**
```ini
maxretry = 10
bantime = 600      # 10 分钟
findtime = 3600
```

## 🔧 故障排除

### Filter 不匹配

```bash
# 1. 检查 Caddy 实际日志格式
tail -10 /var/log/caddy/s3-access.log

# 2. 手动测试 filter
sudo fail2ban-regex /var/log/caddy/s3-access.log /etc/fail2ban/filter.d/caddy-s3.conf --print-all-matched

# 3. 查看失败原因
sudo fail2ban-regex /var/log/caddy/s3-access.log /etc/fail2ban/filter.d/caddy-s3.conf --print-no-matched
```

### 误封正常用户

```bash
# 临时解封
sudo fail2ban-client set caddy-s3 unbanip 1.2.3.4

# 添加白名单（在 jail 配置中）
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 192.168.0.0/16
```

### Caddy 日志未生成

```bash
# 检查 Caddy 配置
caddy validate --config /etc/caddy/Caddyfile

# 检查日志目录权限
ls -la /var/log/caddy/

# 查看 Caddy 错误日志
sudo journalctl -u caddy -n 50
```

## 🛡️ 高级配置

### 1. 组合 Caddy + SeaweedFS 日志

同时监控两个日志源：

```ini
[caddy-s3]
enabled = true
port = http,https
filter = caddy-s3
logpath = /var/log/caddy/s3-access.log
         /var/log/seaweedfs/s3.log
maxretry = 3
bantime = 14400
findtime = 3600
```

### 2. 基于频率的封禁

使用 fail2ban 的 recidive（惯犯）功能：

```ini
[caddy-s3-recidive]
enabled = true
filter = caddy-s3
logpath = /var/log/caddy/s3-access.log
maxretry = 1
findtime = 86400   # 24 小时
bantime = 604800   # 7 天
action = iptables-allports[name=caddy-s3-recidive]
```

### 3. 集成 CloudFlare

如果使用 CloudFlare，需要获取真实 IP：

```caddyfile
s3.example.com {
    log {
        output file /var/log/caddy/s3-access.log
        format json
    }

    # 信任 CloudFlare IP
    trusted_proxies cloudflare

    reverse_proxy localhost:8333 {
        header_up X-Real-IP {header.CF-Connecting-IP}
    }
}
```

## 📚 相关资源

- [Caddy 日志文档](https://caddyserver.com/docs/caddyfile/directives/log)
- [SeaweedFS S3 文档](https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API)
- [fail2ban 官方文档](https://www.fail2ban.org/)
- [AWS S3 错误代码](https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html)

## 🔐 安全建议

1. **使用强密钥** - S3 Access Key 和 Secret Key 应该足够复杂
2. **限制 IP 范围** - 如果可能，只允许特定 IP 访问
3. **启用 HTTPS** - 始终使用 TLS 加密
4. **定期轮换密钥** - 定期更换 S3 凭证
5. **最小权限原则** - S3 bucket 权限设置为最小必要权限
6. **监控告警** - 配置 Discord/Email 通知及时了解异常
