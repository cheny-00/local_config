# SSH 安全配置工具

SSH 安全配置工具集，提供公钥配置和安全加固功能。

## 功能特性

### 1. SSH 公钥配置 (setup_key)
- 自动创建 `.ssh` 目录并设置正确权限（700）
- 交互式输入或通过环境变量提供 SSH 公钥
- 验证公钥格式（支持 ssh-rsa、ssh-ed25519、ecdsa 等）
- 自动添加到 `authorized_keys` 并设置权限（600）
- 检查公钥是否已存在，避免重复添加

### 2. SSH 安全加固 (harden)
自动配置以下安全项：
- `PasswordAuthentication no` - 禁用密码登录
- `PermitRootLogin prohibit-password` - 禁止 root 密码登录（仅允许密钥）
- `PubkeyAuthentication yes` - 启用公钥认证
- `PermitEmptyPasswords no` - 禁止空密码
- `ChallengeResponseAuthentication no` - 禁用挑战响应认证
- `X11Forwarding no` - 禁用 X11 转发
- `MaxAuthTries 3` - 最多 3 次认证尝试
- `MaxSessions 10` - 最多 10 个会话

### 3. 安全措施
- 修改前自动备份 SSH 配置（带时间戳）
- 修改后验证配置文件语法
- 验证失败自动恢复备份
- 自动重启 SSH 服务应用配置

## 使用方法

### 基本命令

```bash
# 显示帮助信息
sudo bash ssh_security.sh help

# 完整配置流程（交互式，默认当前用户）
sudo bash ssh_security.sh full

# 为指定用户完整配置
sudo bash ssh_security.sh full john

# 仅配置 SSH 公钥（交互式）
sudo bash ssh_security.sh setup_key

# 为指定用户配置 SSH 公钥
sudo bash ssh_security.sh setup_key john

# 仅加固 SSH 配置
sudo bash ssh_security.sh harden
```

### 使用场景

#### 场景 1: 新服务器初始化
为新用户配置 SSH 公钥并加固 SSH 配置：

```bash
# 交互式完整配置
sudo bash ssh_security.sh full

# 或为特定用户配置
sudo bash ssh_security.sh full myuser
```

按提示：
1. 输入 SSH 公钥
2. 确认是否禁用密码登录

#### 场景 2: 仅添加 SSH 公钥
只添加公钥，不修改 SSH 配置：

```bash
# 交互式为当前用户添加
sudo bash ssh_security.sh setup_key

# 为特定用户添加
sudo bash ssh_security.sh setup_key john
```

#### 场景 3: 仅加固现有 SSH 配置
已经配置好公钥，只需要加固 SSH：

```bash
sudo bash ssh_security.sh harden
```

#### 场景 4: 非交互式使用
通过环境变量提供公钥（适合自动化脚本）：

```bash
# 设置公钥环境变量
export SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3Nza... user@host"

# 为用户 john 配置
sudo -E bash ssh_security.sh setup_key john
```

## 在 init.sh 中集成

init.sh 会在配置完成后询问是否配置 SSH 安全：

```bash
# 运行 init.sh
sudo bash init.sh myuser
```

在最后阶段会提示：
```
是否配置 SSH 安全? (y/n):
```

选择 `y` 后会自动调用 `ssh_security.sh` 进行完整配置。

## 注意事项

### 重要警告

1. **禁用密码登录前确保公钥可用**
   - 加固 SSH 配置会禁用密码登录
   - 请务必确保公钥已正确配置且可以登录
   - 建议先在另一个 SSH 会话中测试公钥登录

2. **保留当前 SSH 连接**
   - 在重启 SSH 服务前，保持至少一个 SSH 连接
   - 这样即使配置错误也可以恢复

3. **备份文件位置**
   - 每次加固都会创建备份文件
   - 格式：`/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS`
   - 如需恢复：`sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config`

### 支持的公钥类型

- `ssh-rsa` - RSA 密钥
- `ssh-ed25519` - Ed25519 密钥（推荐）
- `ecdsa-sha2-nistp256` - ECDSA 256 位
- `ecdsa-sha2-nistp384` - ECDSA 384 位
- `ecdsa-sha2-nistp521` - ECDSA 521 位

### 测试公钥登录

在禁用密码登录前，建议先测试公钥登录：

```bash
# 从本地测试（在另一个终端）
ssh -i ~/.ssh/id_ed25519 user@server

# 如果成功，再运行加固命令
```

## 故障排除

### 公钥登录失败

1. 检查权限：
```bash
# .ssh 目录权限应为 700
ls -ld ~/.ssh

# authorized_keys 权限应为 600
ls -l ~/.ssh/authorized_keys
```

2. 检查 SELinux（如果启用）：
```bash
restorecon -R ~/.ssh
```

3. 查看 SSH 日志：
```bash
sudo tail -f /var/log/auth.log  # Debian/Ubuntu
sudo tail -f /var/log/secure     # CentOS/RHEL
```

### 恢复密码登录

如果需要恢复密码登录：

```bash
# 恢复备份
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config

# 或手动修改
sudo vim /etc/ssh/sshd_config
# 找到 PasswordAuthentication 改为 yes

# 重启 SSH 服务
sudo systemctl restart sshd  # 或 ssh
```

## 最佳实践

1. **使用 Ed25519 密钥**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **定期更新 SSH 密钥**
   - 建议每 1-2 年更新一次
   - 添加新密钥前不要删除旧密钥

3. **使用不同密钥访问不同服务器**
   - 避免使用同一个密钥访问所有服务器
   - 降低密钥泄露风险

4. **为密钥设置密码短语**
   - 即使密钥文件被盗，仍需密码才能使用
   - 使用 ssh-agent 避免重复输入

## 示例：完整的服务器初始化流程

```bash
# 1. 运行 init.sh 安装基础环境
sudo bash init.sh myuser

# 在最后提示时选择配置 SSH 安全

# 2. 或者单独配置 SSH（如果之前跳过了）
sudo bash ssh/ssh_security.sh full myuser

# 3. 在另一个终端测试公钥登录
ssh myuser@server

# 4. 确认可以登录后，关闭密码登录（如果还没有）
sudo bash ssh/ssh_security.sh harden
```

## 相关文档

- [OpenSSH 官方文档](https://www.openssh.com/)
- [SSH 最佳实践](https://infosec.mozilla.org/guidelines/openssh)
