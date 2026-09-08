#!/bin/sh
#
# @provider: cloudflare
# @display: Cloudflare
# @key_field: zone_id
# @secret_field: api_token
#

log_info() { echo "[Cloudflare] $1" >&2; }
log_ok()   { echo "[Cloudflare] ✓ $1" >&2; }
log_err()  { echo "[Cloudflare] ✗ $1" >&2; }

ENDPOINT="https://api.cloudflare.com/client/v4"

# 用法: mddns-cloudflare.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

ZONE_ID="${KEY:-${CLOUDFLARE_ZONE_ID}}"
API_TOKEN="${SECRET:-${CLOUDFLARE_API_TOKEN}}"

if [ -z "$API_TOKEN" ]; then
    echo "错误: 请提供 api_token" >&2
    exit 1
fi

# 检测 HTTP 客户端
if command -v curl >/dev/null 2>&1; then
    HTTP_CLIENT="curl"
elif command -v wget >/dev/null 2>&1; then
    HTTP_CLIENT="wget"
else
    echo "错误: 需要 curl 或 wget" >&2
    exit 1
fi

req() {
    method="$1"; path="$2"; data="$3"
    url="${ENDPOINT}${path}"
    if [ "$HTTP_CLIENT" = "curl" ]; then
        if [ -n "$data" ]; then
            curl -s -m 30 -X "$method" \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$data" "$url"
        else
            curl -s -m 30 -X "$method" \
                -H "Authorization: Bearer $API_TOKEN" \
                "$url"
        fi
    else
        # wget (GNU wget 支持 --header/--method/--body-data)
        if [ -n "$data" ]; then
            wget -q -O - -T 30 \
                --header="Authorization: Bearer $API_TOKEN" \
                --header="Content-Type: application/json" \
                --method="$method" \
                --body-data="$data" \
                "$url"
        else
            wget -q -O - -T 30 \
                --header="Authorization: Bearer $API_TOKEN" \
                --method="$method" \
                "$url"
        fi
    fi
}

# 获取 Zone ID: 优先用户配置, 否则实时查询 (不做缓存: 请求量远低于限额,
# 且避免域名重建后 zone ID 变化导致缓存过期无法自愈)
# 查询失败 (网络错误/API错误/域名不在账号下) 返回非零, 调用方必须中止,
# 避免空 zone 拼出 /zones//dns_records 触发 7003 错误
get_zone() {
    domain="$1"
    if [ -n "$ZONE_ID" ]; then
        echo "$ZONE_ID"
        return 0
    fi

    log_info "查询 Zone: ${domain}"
    result=$(req "GET" "/zones?name=${domain}")
    if [ -z "$result" ]; then
        log_err "查询 Zone 失败: ${domain} (网络错误或无响应)"
        return 1
    fi
    if printf '%s' "$result" | grep -q '"success":false'; then
        log_err "查询 Zone 失败: ${domain} API返回错误"
        log_err "API返回: $result"
        return 1
    fi
    zone_id=$(printf '%s' "$result" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -z "$zone_id" ]; then
        log_err "未找到 Zone: ${domain} (请确认域名已在此账号下)"
        return 1
    fi
    echo "$zone_id"
}

get_full_name() {
    sub="$1"; domain="$2"
    if [ -z "$sub" ] || [ "$sub" = "@" ]; then
        echo "$domain"
    else
        echo "${sub}.${domain}"
    fi
}

get_record() {
    domain="$1"; sub="$2"; type="$3"
    zone=$(get_zone "$domain") || exit 1
    name=$(get_full_name "$sub" "$domain")
    log_info "查询记录: ${name} (${type})"
    result=$(req "GET" "/zones/${zone}/dns_records?name=${name}&type=${type}")
    # 请求失败 (网络错误/超时/无响应): 返回非零退出码, 主程序中止本次更新直接重试,
    # 避免误判为"记录不存在"走添加流程, 触发 81058 记录已存在错误
    if [ -z "$result" ]; then
        log_err "查询请求失败: ${name} (${type}) (网络错误或无响应)"
        exit 1
    fi
    # API 返回错误 (认证失败/参数错误等): 同样中止, 不走添加
    if printf '%s' "$result" | grep -q '"success":false'; then
        log_err "查询记录失败: ${name} (${type}) API返回错误"
        log_err "API返回: $result"
        exit 1
    fi
    id=$(printf '%s' "$result" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    val=$(printf '%s' "$result" | grep -o '"content":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$id" ]; then
        log_ok "查询记录成功: ${name} (${type}) -> ID=${id}, Content=${val}"
        echo "$id $val"
    else
        # API 确认查询成功但无记录: 记录确实不存在, 主程序走添加流程
        log_info "记录不存在: ${name} (${type})"
    fi
}

add_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"
    zone=$(get_zone "$domain")
    name=$(get_full_name "$sub" "$domain")
    log_info "添加记录: ${name} (${type}) -> ${val}"
    data="{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$val\",\"ttl\":$ttl,\"proxied\":false}"
    result=$(req "POST" "/zones/${zone}/dns_records" "$data")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "添加记录成功: ${name} (${type}) -> ${val}"
        echo "添加成功"
    else
        log_err "添加记录失败: ${name} (${type}) -> ${val}"
        log_err "API返回: $result"
    fi
}

update_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"; id="$6"
    zone=$(get_zone "$domain") || exit 1
    name=$(get_full_name "$sub" "$domain")
    log_info "更新记录: ${name} (${type}) -> ${val} (ID=${id})"
    data="{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$val\",\"ttl\":$ttl,\"proxied\":false}"
    result=$(req "PUT" "/zones/${zone}/dns_records/${id}" "$data")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "更新记录成功: ${name} (${type}) -> ${val} (ID=${id})"
        echo "更新成功"
    else
        log_err "更新记录失败: ${name} (${type}) -> ${val} (ID=${id})"
        log_err "API返回: $result"
    fi
}

delete_record() {
    domain="$1"; id="$2"
    zone=$(get_zone "$domain")
    log_info "删除记录: ${domain} (ID=${id})"
    result=$(req "DELETE" "/zones/${zone}/dns_records/${id}")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "删除记录成功: ${domain} (ID=${id})"
        echo "删除成功"
    else
        log_err "删除记录失败: ${domain} (ID=${id})"
        log_err "API返回: $result"
    fi
}

case "$ACTION" in
    get)    get_record "$DOMAIN" "$SUB" "$TYPE" ;;
    add)    add_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" ;;
    update) update_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" "$RECORD_ID" ;;
    delete) delete_record "$DOMAIN" "$RECORD_ID" ;;
    *)      echo "用法: $0 {get|add|update|delete} <参数...>" >&2; exit 1 ;;
esac
