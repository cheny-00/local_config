# Fail2ban 安装方式对比

## 📊 三种安装方式

| 方式 | 脚本 | 运行身份 | 适用场景 | 推荐度 |
|------|------|---------|---------|--------|
| **智能提权** | `install-smart.sh` | 普通用户 | 个人开发环境 | ⭐⭐⭐⭐⭐ |
| **分离安装** | `install-user.sh` + `install-system.sh` | 分别执行 | 多用户环境 | ⭐⭐⭐⭐ |
| **完全 root** | `install.sh` | root | 单用户/root 环境 | ⭐⭐⭐ |

## 🎯 方式 1: 智能提权（推荐）

### 特点

- ✅ 普通用户运行
- ✅ 需要时自动 sudo
- ✅ 最小权限原则
- ✅ 用户环境隔离

### 使用方式

```bash
# 普通用户直接运行
bash install-smart.sh
```

### 安装路径

```
用户级：
  ~/.local/bin/uv
  ~/workspace/fail2ban/fail2ban-discord/

系统级（自动 sudo）：
  /etc/fail2ban/action.d/
  /etc/fail2ban/filter.d/
  /usr/local/bin/fail2ban-discord-notify
```

### 优点

- 🟢 符合 Linux 最佳实践
- 🟢 用户环境独立
- 🟢 易于卸载和升级
- 🟢 多用户友好

### 缺点

- 🟡 需要 sudo 权限
- 🟡 会多次提示密码

## 🎯 方式 2: 分离安装

### 特点

- ✅ 用户/系统完全分离
- ✅ 职责清晰
- ✅ 灵活控制

### 使用方式

```bash
# 步骤 1: 用户级安装（不需要 sudo）
bash install-user.sh

# 步骤 2: 系统级安装（需要 sudo）
sudo bash install-system.sh
```

### 安装路径

同方式 1

### 优点

- 🟢 职责分离清晰
- 🟢 可以只安装用户级部分
- 🟢 便于自动化部署

### 缺点

- 🟡 需要运行两次
- 🟡 稍微复杂

## 🎯 方式 3: 完全 root（原始方式）

### 特点

- ❌ 必须 root 运行
- ❌ 所有文件属于 root
- ⚠️ 不推荐用于多用户环境

### 使用方式

```bash
# 以 root 运行
sudo bash install.sh
```

### 安装路径

```
全部在 root 下：
  /root/.local/bin/uv
  /root/workspace/fail2ban/fail2ban-discord/
  /etc/fail2ban/...
  /usr/local/bin/fail2ban-discord-notify
```

### 优点

- 🟢 一次完成
- 🟢 简单直接

### 缺点

- 🔴 违反最小权限原则
- 🔴 普通用户无法使用 uv
- 🔴 难以在多用户环境使用
- 🟡 升级和维护不便

## 🔍 详细对比

### 1. 权限需求

| 操作 | 智能提权 | 分离安装 | 完全 root |
|------|---------|---------|-----------|
| 安装 uv | 用户 | 用户 | root (sudo -u) |
| Python 项目 | 用户 | 用户 | root (sudo -u) |
| /etc/fail2ban/ | sudo | sudo | root |
| /usr/local/bin/ | sudo | sudo | root |

### 2. 文件所有者

| 文件 | 智能提权 | 分离安装 | 完全 root |
|------|---------|---------|-----------|
| ~/.local/bin/uv | user:user | user:user | root:root |
| ~/workspace/ | user:user | user:user | root:root |
| /etc/fail2ban/ | root:root | root:root | root:root |

### 3. 使用场景

#### 个人开发环境
```
推荐: 智能提权 ⭐⭐⭐⭐⭐
原因: 简单，符合最佳实践
```

#### 生产服务器（单用户）
```
推荐: 智能提权 或 分离安装 ⭐⭐⭐⭐
原因: 安全，易维护
```

#### 多用户服务器
```
推荐: 分离安装 ⭐⭐⭐⭐⭐
原因: 每个用户独立环境
```

#### Docker/容器环境
```
推荐: 完全 root ⭐⭐⭐
原因: 容器内只有 root
```

## 🚀 快速决策

### 如果你不确定，问自己：

**Q1: 你是普通用户还是 root？**
- 普通用户 → 使用智能提权
- root → 使用完全 root

**Q2: 服务器有多个用户吗？**
- 是 → 使用分离安装
- 否 → 使用智能提权

**Q3: 你想要最简单的方式？**
- 是 → 使用智能提权
- 否，我想要完全控制 → 使用分离安装

## 🔄 迁移指南

### 从完全 root 迁移到智能提权

```bash
# 1. 卸载 root 版本
sudo rm -rf /root/workspace/fail2ban/fail2ban-discord
sudo rm /root/.local/bin/uv

# 2. 安装用户版本
bash install-smart.sh

# 3. 更新包装脚本（自动完成）
# /usr/local/bin/fail2ban-discord-notify 会指向新路径
```

### 从分离安装迁移到智能提权

```bash
# 已经是用户级安装，只需确认系统级配置
sudo bash install-smart.sh
# 或者只运行系统级部分
sudo bash install-system.sh
```

## 💡 最佳实践建议

### 推荐配置

1. **个人 VPS**:
   ```bash
   # 使用智能提权
   bash install-smart.sh
   ```

2. **公司服务器（多用户）**:
   ```bash
   # 每个用户分别安装
   bash install-user.sh
   # 管理员安装系统级（一次）
   sudo bash install-system.sh
   ```

3. **Docker 容器**:
   ```bash
   # 使用原始方式
   sudo bash install.sh
   ```

### 为什么推荐智能提权？

1. **符合 Unix 哲学**
   - 用户数据在用户目录
   - 系统配置在系统目录

2. **安全性更好**
   - 最小权限原则
   - 减少 root 暴露面

3. **维护更容易**
   - 用户可以自己更新 Python 环境
   - 不影响其他用户

4. **卸载更干净**
   - 删除用户目录即可
   - 系统配置独立管理

## ❓ FAQ

### Q: 为什么不能完全不需要 root？

A: 因为 fail2ban 的配置文件必须在 `/etc/fail2ban/`，包装脚本必须在 `/usr/local/bin/`，这些都需要 root 权限。

### Q: 可以把配置文件放在用户目录吗？

A: 技术上可以，但 fail2ban 服务默认读取 `/etc/fail2ban/`，修改会增加复杂度。

### Q: 智能提权会提示多少次密码？

A: 通常 3-5 次（安装 fail2ban、复制配置、创建脚本）。可以配置 sudo 缓存减少提示。

### Q: 我该删除 install.sh 吗？

A: 不需要。它仍然适用于某些场景（如 Docker）。但推荐优先使用 install-smart.sh。

## 📚 相关文档

- [sudo 最佳实践](https://www.sudo.ws/docs/man/sudoers.man/)
- [Linux 文件系统层次标准](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [Python 用户级安装](https://docs.python.org/3/install/index.html#alternate-installation-the-user-scheme)
