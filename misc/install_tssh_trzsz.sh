#!/bin/bash

# 安装 tssh 和 trzsz
# 使用 trzsz PPA 源

set -e

echo "正在安装 curl 和 gpg..."
apt install -y curl gpg

echo "正在添加 trzsz GPG 密钥..."
curl -s 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x7074ce75da7cc691c1ae1a7c7e51d1ad956055ca' \
    | gpg --dearmor -o /usr/share/keyrings/trzsz.gpg

echo "正在添加 trzsz PPA 源..."
echo 'deb [signed-by=/usr/share/keyrings/trzsz.gpg] https://ppa.launchpadcontent.net/trzsz/ppa/ubuntu jammy main' \
    | tee /etc/apt/sources.list.d/trzsz.list

echo "正在更新 apt 缓存..."
apt update

echo "正在安装 tssh..."
apt install -y tssh

echo "正在安装 trzsz..."
apt install -y trzsz

echo "安装完成！"
echo "tssh 版本: $(tssh --version 2>/dev/null || echo '未找到')"
echo "trzsz 版本: $(trzsz --version 2>/dev/null || echo '未找到')"
