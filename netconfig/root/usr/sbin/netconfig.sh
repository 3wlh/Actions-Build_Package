#!/bin/sh
set -e

# 配置文件路径
CONFIG_FILE="/etc/config/netconfig"

# 读取LuCI配置
get_config() {
    uci get "$CONFIG_FILE".@general[]."$1" 2>/dev/null || echo "$2"
}

# 生成Device Key（解密密钥，基于eth0 MAC）
generate_key() {
    local mac=$(ip -o link show eth0 2>/dev/null|grep -Eo "permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"|awk '{print $NF}')
    local key=$([ -n "$mac" ] && echo -n "$mac"|md5sum|awk '{print $1}'|cut -c9-24)
    [ -z "$key" ] && mac=$(cat /sys/class/net/eth0/address 2>/dev/null) && key=$([ -n "$mac" ] && echo -n "$mac"|md5sum|awk '{print $1}'|cut -c9-24)
    echo "$key"
}

# 解密并应用配置脚本
pull_apply() {
    local config_url=$(get_config "config_url" "")
    local config_key=$(get_config "config_key" "$(generate_key)")  # 解密密钥（优先用配置的Key）
    # 检查解密密钥
    if [ -z "$config_key" ]; then
        echo "错误: 解密密钥为空，无法解密脚本"
        exit 1
    fi
    echo -e "URL: ${config_url}\n"
    echo -e "Key: ${config_key}\n"
    if command -v openssl >/dev/null 2>&1; then
       wget -qO - ${config_url} | bash -s ${config_key}       
    else
        echo "错误: 未安装openssl-util（解密必需）"
        exit 1
    fi
    echo "配置应用完成"
}

# 主逻辑
case "$1" in
    pull_apply)
        pull_apply
        ;;
    *)
        echo "使用方法: $0 {pull|apply}"
        exit 1
        ;;
esac

exit 0
