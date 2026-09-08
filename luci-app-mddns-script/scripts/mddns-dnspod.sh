#!/bin/sh
#
# @provider: dnspod
# @display: DNSPod (腾讯云)
# @key_field: secret_id
# @secret_field: secret_key
#
# 腾讯云 API 3.0 (dnspod.tencentcloudapi.com), TC3-HMAC-SHA256 签名 (内置签名工具)
# 签名规范: https://cloud.tencent.com/document/api/1427/56189
#

log_info() { echo "[DNSPod] $1" >&2; }
log_ok()   { echo "[DNSPod] ✓ $1" >&2; }
log_err()  { echo "[DNSPod] ✗ $1" >&2; }

MDDNS_BIN="${MDDNS_BIN:-mddns-scripts}"
ENDPOINT_HOST="dnspod.tencentcloudapi.com"
ENDPOINT="https://${ENDPOINT_HOST}"
API_VERSION="2021-03-23"

# 用法: mddns-dnspod.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

SECRET_ID="${KEY:-${DNSPOD_SECRET_ID}}"
SECRET_KEY="${SECRET:-${DNSPOD_SECRET_KEY}}"

if [ -z "$SECRET_ID" ] || [ -z "$SECRET_KEY" ]; then
    echo "错误: 请提供 key 和 secret" >&2
    exit 1
fi

# TC3 签名依赖主程序内置签名工具 (MDDNS_BIN 由主程序启动时注入)
if ! command -v "$MDDNS_BIN" >/dev/null 2>&1; then
    log_err "签名工具不可用: $MDDNS_BIN"
    exit 1
fi

# 检测 HTTP 客户端
if command -v curl >/dev/null 2>&1; then
    HTTP_CLIENT="curl"
elif command -v wget >/dev/null 2>&1; then
    HTTP_CLIENT="wget"    # TC3 需要 POST JSON + 自定义头, 需 GNU wget (--header/--method/--body-data)
else
    echo "错误: 需要 curl 或 wget" >&2
    exit 1
fi

# ── TC3-HMAC-SHA256 签名 ──
# 用法: build_authorization <action> <payload> <timestamp>
# 输出 Authorization 头的值 (签名与时间戳必须同源, 故由 send_request 统一生成传入)
build_authorization() {
    b_action="$1"; b_payload="$2"; b_ts="$3"
    service=$(printf '%s' "$ENDPOINT_HOST" | cut -d '.' -f1)
    date_utc=$(date -u -d @"$b_ts" +"%Y-%m-%d" 2>/dev/null || date -u +"%Y-%m-%d")
    scope="${date_utc}/${service}/tc3_request"
    action_lower=$(printf '%s' "$b_action" | tr 'A-Z' 'a-z')
    hashed_payload=$(printf '%s' "$b_payload" | "$MDDNS_BIN" -sha256)

    # 规范请求串 (POST + / + 空查询串 + 三个小写头 + 签名头列表 + 哈希后的 body)
    canonical_request=$(printf 'POST\n/\n\ncontent-type:application/json\nhost:%s\nx-tc-action:%s\n\ncontent-type;host;x-tc-action\n%s' \
        "$ENDPOINT_HOST" "$action_lower" "$hashed_payload")
    hashed_request=$(printf '%s' "$canonical_request" | "$MDDNS_BIN" -sha256)

    # 待签名串
    string_to_sign=$(printf 'TC3-HMAC-SHA256\n%s\n%s\n%s' "$b_ts" "$scope" "$hashed_request")

    # 三层派生密钥 (-hmac-hex 把上一层的 hex 输出当原始字节密钥, 实现层间传递)
    secret_date=$(printf '%s' "$date_utc" | "$MDDNS_BIN" -sha256 -hmac "TC3${SECRET_KEY}")
    secret_service=$(printf '%s' "$service" | "$MDDNS_BIN" -sha256 -hmac-hex "$secret_date")
    secret_signing=$(printf '%s' 'tc3_request' | "$MDDNS_BIN" -sha256 -hmac-hex "$secret_service")

    # 最终签名
    signature=$(printf '%s' "$string_to_sign" | "$MDDNS_BIN" -sha256 -hmac-hex "$secret_signing")

    # Authorization 头
    printf 'TC3-HMAC-SHA256 Credential=%s/%s, SignedHeaders=content-type;host;x-tc-action, Signature=%s' \
        "$SECRET_ID" "$scope" "$signature"
}

# ── API 请求 (POST JSON + X-TC-* 头) ──
# 用法: send_request <action> <json_payload>
send_request() {
    s_action="$1"; s_payload="$2"
    s_ts=$(date +%s)
    s_auth=$(build_authorization "$s_action" "$s_payload" "$s_ts")
    if [ "$HTTP_CLIENT" = "curl" ]; then
        curl -s --connect-timeout 5 --max-time 15 -X POST "$ENDPOINT" \
            -H "Content-Type: application/json" \
            -H "X-TC-Action: $s_action" \
            -H "X-TC-Version: $API_VERSION" \
            -H "X-TC-Timestamp: $s_ts" \
            -H "Authorization: $s_auth" \
            -d "$s_payload" 2>/dev/null
    else
        wget -q -O - --timeout=15 --tries=1 \
            --header="Content-Type: application/json" \
            --header="X-TC-Action: $s_action" \
            --header="X-TC-Version: $API_VERSION" \
            --header="X-TC-Timestamp: $s_ts" \
            --header="Authorization: $s_auth" \
            --method=POST --body-data="$s_payload" \
            "$ENDPOINT" 2>/dev/null
    fi
}

# ── 响应检查: 空响应/含 Error 视为失败 ──
# "ResourceNotFound.NoDataOfRecord" 除外 (记录不存在属正常, 主程序会走添加流程)
# 用法: check_api_error <result> ; 返回 0=正常或未找到, 1=失败(已记录日志)
check_api_error() {
    if [ -z "$1" ]; then
        log_err "API 无响应 (网络或认证失败)"
        return 1
    fi
    if printf '%s' "$1" | grep -q '"Error"'; then
        if printf '%s' "$1" | grep -q 'ResourceNotFound.NoDataOfRecord'; then
            return 0
        fi
        log_err "API 错误: $1"
        return 1
    fi
    return 0
}

get_record() {
    domain="$1"; sub="$2"; type="$3"
    log_info "查询记录: ${sub}.${domain} (${type})"
    payload="{\"Domain\":\"$domain\",\"RecordType\":\"$type\",\"Subdomain\":\"$sub\",\"Limit\":1}"
    result=$(send_request "DescribeRecordList" "$payload")
    check_api_error "$result" || exit 1
    id=$(printf '%s' "$result" | grep -o '"RecordId":[[:space:]]*[0-9][0-9]*' | head -1 | tr -cd '0-9')
    val=$(printf '%s' "$result" | grep -o '"Value":[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$id" ]; then
        log_ok "查询记录成功: ${sub}.${domain} (${type}) -> ID=${id}, Value=${val}"
        echo "$id $val"
    else
        # API 确认查询成功但无记录: 记录确实不存在, 主程序走添加流程
        log_info "记录不存在: ${sub}.${domain} (${type})"
    fi
}

add_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"
    log_info "添加记录: ${sub}.${domain} (${type}) -> ${val}"
    payload="{\"Domain\":\"$domain\",\"SubDomain\":\"$sub\",\"RecordType\":\"$type\",\"RecordLine\":\"默认\",\"Value\":\"$val\"}"
    result=$(send_request "CreateRecord" "$payload")
    if check_api_error "$result"; then
        log_ok "添加记录成功: ${sub}.${domain} (${type}) -> ${val}"
        echo "添加成功"
    else
        exit 1
    fi
}

update_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"; id="$6"
    log_info "更新记录: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
    payload="{\"Domain\":\"$domain\",\"SubDomain\":\"$sub\",\"RecordType\":\"$type\",\"RecordLine\":\"默认\",\"RecordId\":$id,\"Value\":\"$val\"}"
    result=$(send_request "ModifyRecord" "$payload")
    if check_api_error "$result"; then
        log_ok "更新记录成功: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
        echo "更新成功"
    else
        exit 1
    fi
}

delete_record() {
    domain="$1"; id="$2"
    log_info "删除记录: ${domain} (ID=${id})"
    payload="{\"Domain\":\"$domain\",\"RecordId\":$id}"
    result=$(send_request "DeleteRecord" "$payload")
    if check_api_error "$result"; then
        log_ok "删除记录成功: ${domain} (ID=${id})"
        echo "删除成功"
    else
        exit 1
    fi
}

case "$ACTION" in
    get)    get_record "$DOMAIN" "$SUB" "$TYPE" ;;
    add)    add_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" ;;
    update) update_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" "$RECORD_ID" ;;
    delete) delete_record "$DOMAIN" "$RECORD_ID" ;;
    *)      echo "用法: $0 {get|add|update|delete} <参数...>" >&2; exit 1 ;;
esac
