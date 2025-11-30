#!/usr/bin/env python3
"""
fail2ban Discord webhook notification script with IP geolocation and proxy support
Managed by uv
"""
import sys
import json
import socket
import requests
import os
from datetime import datetime

# 代理配置
def get_proxies():
    """获取代理配置"""
    http_proxy = os.environ.get('HTTP_PROXY') or os.environ.get('http_proxy')
    https_proxy = os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy')
    
    if http_proxy or https_proxy:
        proxies = {}
        if http_proxy:
            proxies['http'] = http_proxy
        if https_proxy:
            proxies['https'] = https_proxy
        return proxies
    
    config_file = '/etc/fail2ban/discord-proxy.conf'
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip().lower()
                            value = value.strip()
                            if key == 'http_proxy':
                                return {'http': value, 'https': value}
                            elif key == 'https_proxy':
                                return {'https': value}
        except Exception as e:
            print(f"Error reading proxy config: {e}", file=sys.stderr)
    
    return None

def get_ip_info(ip):
    """获取 IP 地理位置信息"""
    proxies = get_proxies()
    
    try:
        response = requests.get(
            f"http://ip-api.com/json/{ip}",
            params={
                "fields": "status,country,countryCode,region,regionName,city,isp,org,as,query"
            },
            timeout=10,
            proxies=proxies
        )
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "success":
                return data
    except Exception as e:
        print(f"Error getting IP info: {e}", file=sys.stderr)
    return None

def format_ip_info(ip_data):
    """格式化 IP 信息为 Discord 字段"""
    if not ip_data:
        return "无法获取地理位置信息"
    
    country = ip_data.get("country", "Unknown")
    country_code = ip_data.get("countryCode", "").lower()
    region = ip_data.get("regionName", "Unknown")
    city = ip_data.get("city", "Unknown")
    isp = ip_data.get("isp", "Unknown")
    org = ip_data.get("org", "Unknown")
    as_info = ip_data.get("as", "Unknown")
    
    flag = f":flag_{country_code}:" if country_code else ""
    
    return (
        f"{flag} **{country}**\n"
        f"城市: {city}, {region}\n"
        f"ISP: {isp}\n"
        f"组织: {org}\n"
        f"AS: {as_info}"
    )

def format_duration(seconds):
    """格式化时长显示"""
    try:
        seconds = int(float(seconds))
        
        if seconds < 0:
            return "永久"
        
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        secs = seconds % 60
        
        parts = []
        if hours > 0:
            parts.append(f"{hours}小时")
        if minutes > 0:
            parts.append(f"{minutes}分钟")
        if secs > 0 or not parts:
            parts.append(f"{secs}秒")
        
        return "".join(parts) + f" ({seconds}s)"
    except:
        return str(seconds)

def send_discord_notification(webhook_url, color, title, description, fields=None):
    """发送 Discord 通知"""
    if not webhook_url or webhook_url == "YOUR_DISCORD_WEBHOOK_URL_HERE":
        print("Discord webhook URL not configured, skipping notification", file=sys.stderr)
        return
    
    proxies = get_proxies()
    hostname = socket.gethostname()
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    embed = {
        "title": title,
        "description": description,
        "color": color,
        "footer": {"text": f"fail2ban on {hostname}"},
        "timestamp": timestamp
    }
    
    if fields:
        embed["fields"] = fields
    
    payload = {"embeds": [embed]}
    
    try:
        if proxies:
            print(f"Using proxy: {proxies}", file=sys.stderr)
        
        response = requests.post(
            webhook_url,
            json=payload,
            timeout=30,
            proxies=proxies
        )
        if response.status_code not in [200, 204]:
            print(f"Discord webhook error: {response.status_code} - {response.text}", file=sys.stderr)
        else:
            print(f"Discord notification sent successfully", file=sys.stderr)
    except Exception as e:
        print(f"Error sending Discord notification: {e}", file=sys.stderr)

def main():
    if len(sys.argv) < 3:
        print("Usage: discord_notify.py <action> <jail_name> [args...] <webhook_url>", file=sys.stderr)
        sys.exit(1)
    
    action = sys.argv[1]
    jail_name = sys.argv[2]
    
    COLOR_RED = 15158332
    COLOR_GREEN = 3066993
    COLOR_BLUE = 3447003
    COLOR_GRAY = 9807270
    
    if action == "start":
        webhook_url = sys.argv[3] if len(sys.argv) > 3 else ""
        send_discord_notification(
            webhook_url,
            COLOR_BLUE,
            "🟢 Jail Started",
            f"Jail **{jail_name}** has been started and is now monitoring."
        )
    
    elif action == "stop":
        webhook_url = sys.argv[3] if len(sys.argv) > 3 else ""
        send_discord_notification(
            webhook_url,
            COLOR_GRAY,
            "⚪ Jail Stopped",
            f"Jail **{jail_name}** has been stopped."
        )
    
    elif action == "ban":
        if len(sys.argv) < 7:
            print(f"Ban action requires at least 7 args, got {len(sys.argv)}: {sys.argv}", file=sys.stderr)
            sys.exit(1)
        
        ip = sys.argv[3]
        failures = sys.argv[4]
        ban_time = sys.argv[5]
        webhook_url = sys.argv[6]
        
        print(f"Ban action: ip={ip}, failures={failures}, ban_time={ban_time}", file=sys.stderr)
        
        formatted_duration = format_duration(ban_time)
        ip_data = get_ip_info(ip)
        ip_info = format_ip_info(ip_data)
        
        fields = [
            {
                "name": "🚫 Banned IP", 
                "value": f"**{ip}**",
                "inline": True
            },
            {
                "name": "⚠️ Failed Attempts", 
                "value": str(failures),
                "inline": True
            },
            {
                "name": "⏱️ Ban Duration", 
                "value": formatted_duration,
                "inline": True
            },
            {
                "name": "📍 Location Information", 
                "value": ip_info,
                "inline": False
            }
        ]
        
        send_discord_notification(
            webhook_url,
            COLOR_RED,
            "🔴 IP Address Banned",
            f"An IP has been banned from jail **{jail_name}**",
            fields
        )
        
        sys.exit(0)
    
    elif action == "unban":
        if len(sys.argv) < 5:
            print(f"Unban action requires at least 5 args, got {len(sys.argv)}: {sys.argv}", file=sys.stderr)
            sys.exit(1)
        
        ip = sys.argv[3]
        webhook_url = sys.argv[4]
        
        print(f"Unban action: ip={ip}", file=sys.stderr)
        
        fields = [
            {
                "name": "✅ Unbanned IP", 
                "value": f"**{ip}**",
                "inline": True
            }
        ]
        
        send_discord_notification(
            webhook_url,
            COLOR_GREEN,
            "🟢 IP Address Unbanned",
            f"An IP has been unbanned from jail **{jail_name}**",
            fields
        )
        
        sys.exit(0)
    
    else:
        print(f"Unknown action: {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()