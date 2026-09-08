#!/bin/sh
#
# @provider: spaceship
# @display: Spaceship
# @key_field: api_key
# @secret_field: api_secret
#

log_info() { echo "[Spaceship] $1" >&2; }
log_ok()   { echo "[Spaceship] ✓ $1" >&2; }
log_err()  { echo "[Spaceship] ✗ $1" >&2; }

ENDPOINT="https://spaceship.dev/api/v1"

# 用法: mddns-spaceship.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

API_KEY="${KEY:-${SPACESHIP_API_KEY}}"
API_SECRET="${SECRET:-${SPACESHIP_API_SECRET}}"

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
    echo "错误: 请提供 key 和 secret" >&2
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
            curl -s --connect-timeout 5 --max-time 15 -X "$method" \
                -H "X-Api-Key: $API_KEY" \
                -H "X-Api-Secret: $API_SECRET" \
                -H "Content-Type: application/json" \
                -d "$data" "$url"
        else
            curl -s --connect-timeout 5 --max-time 15 -X "$method" \
                -H "X-Api-Key: $API_KEY" \
                -H "X-Api-Secret: $API_SECRET" \
                "$url"
        fi
    else
        # wget (GNU wget 支持 --header/--method/--body-data)
        if [ -n "$data" ]; then
            wget -q -O - --timeout=15 --tries=1 \
                --header="X-Api-Key: $API_KEY" \
                --header="X-Api-Secret: $API_SECRET" \
                --header="Content-Type: application/json" \
                --method="$method" \
                --body-data="$data" \
                "$url"
        else
            wget -q -O - --timeout=15 --tries=1 \
                --header="X-Api-Key: $API_KEY" \
                --header="X-Api-Secret: $API_SECRET" \
                --method="$method" \
                "$url"
        fi
    fi
}

get_record() {
    domain="$1"; sub="$2"; type="$3"
    log_info "查询记录: ${sub}.${domain} (${type})"
    result=$(req "GET" "/dns/records/${domain}?take=100&skip=0")
    # 请求失败 (网络错误/超时/无响应): 返回非零退出码, 主程序中止本次更新直接重试,
    # 避免误判为"记录不存在"走添加流程
    if [ -z "$result" ]; then
        log_err "查询请求失败: ${sub}.${domain} (${type}) (网络错误或无响应)"
        exit 1
    fi
    # API 返回错误 (认证失败等): 响应中无 items 字段, 同样中止, 不走添加
    if ! printf '%s' "$result" | grep -q '"items"'; then
        log_err "查询记录失败: ${sub}.${domain} (${type}) API返回错误"
        log_err "API返回: $result"
        exit 1
    fi
    id=$(printf '%s' "$result" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    val=$(printf '%s' "$result" | grep -o '"address":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -z "$val" ]; then
        val=$(printf '%s' "$result" | grep -o '"value":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    if [ -n "$id" ]; then
        log_ok "查询记录成功: ${sub}.${domain} (${type}) -> ID=${id}, Value=${val}"
        echo "$id $val"
    else
        # API 确认查询成功但无记录: 记录确实不存在, 主程序走添加流程
        log_info "记录不存在: ${sub}.${domain} (${type})"
    fi
}

add_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"
    key="address"
    if [ "$type" = "TXT" ]; then
        key="value"
    fi
    log_info "添加记录: ${sub}.${domain} (${type}) -> ${val}"
    data="{\"force\":true,\"items\":[{\"type\":\"$type\",\"name\":\"$sub\",\"ttl\":$ttl,\"$key\":\"$val\"}]}"
    result=$(req "PUT" "/dns/records/${domain}" "$data")
    if printf '%s' "$result" | grep -q '"items"'; then
        log_ok "添加记录成功: ${sub}.${domain} (${type}) -> ${val}"
        echo "添加成功"
    else
        log_err "添加记录失败: ${sub}.${domain} (${type}) -> ${val}"
        log_err "API返回: $result"
    fi
}

update_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"; id="$6"
    key="address"
    if [ "$type" = "TXT" ]; then
        key="value"
    fi
    log_info "更新记录: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
    del="[{\"type\":\"$type\",\"name\":\"$sub\",\"$key\":\"$val\"}]"
    del_result=$(req "DELETE" "/dns/records/${domain}" "$del")
    add_result=$(add_record "$domain" "$sub" "$type" "$val" "$ttl")
    if [ -n "$add_result" ]; then
        log_ok "更新记录成功: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
        echo "更新成功"
    else
        log_err "更新记录失败: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
        log_err "API返回: $del_result"
    fi
}

delete_record() {
    domain="$1"; id="$2"
    log_info "删除记录: ${domain} (ID=${id})"
    result=$(req "DELETE" "/dns/records/${domain}" "[{\"id\":\"$id\"}]")
    if printf '%s' "$result" | grep -q 'null'; then
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
