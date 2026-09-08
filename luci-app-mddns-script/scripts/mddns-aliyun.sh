#!/bin/sh
#
# @provider: aliyun
# @display: 阿里云 DNS
# @key_field: access_key_id
# @secret_field: access_key_secret
#
# 阿里云 DNS RPC API (alidns.aliyuncs.com), HMAC-SHA1 签名 (内置签名工具)
#

log_info() { echo "[阿里云] $1" >&2; }
log_ok()   { echo "[阿里云] ✓ $1" >&2; }
log_err()  { echo "[阿里云] ✗ $1" >&2; }

MDDNS_BIN="${MDDNS_BIN:-mddns-scripts}"
ENDPOINT="https://alidns.aliyuncs.com"

# 用法: mddns-aliyun.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

ACCESS_KEY_ID="${KEY:-${ALIYUN_ACCESS_KEY_ID}}"
ACCESS_KEY_SECRET="${SECRET:-${ALIYUN_ACCESS_SECRET:-${ALIYUN_ACCESS_KEY_SECRET}}}"

if [ -z "$ACCESS_KEY_ID" ] || [ -z "$ACCESS_KEY_SECRET" ]; then
    echo "错误: 请提供 key 和 secret" >&2
    exit 1
fi

# RPC 签名依赖主程序内置签名工具 (MDDNS_BIN 由主程序启动时注入)
if ! command -v "$MDDNS_BIN" >/dev/null 2>&1; then
    log_err "签名工具不可用: $MDDNS_BIN"
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

# HTTP GET 请求
http_get() {
    if [ "$HTTP_CLIENT" = "curl" ]; then
        curl -s --connect-timeout 5 --max-time 15 "$1" 2>/dev/null
    else
        wget -q -O - --timeout=15 --tries=1 "$1" 2>/dev/null
    fi
}


# ── 获取准确 UTC 时间戳: 阿里网关 → 百度 → 淘宝/苏宁 → 本地 ──
get_utc_ts() {
    local t ms

    # 通用: 向指定站点发 HEAD 请求取响应头 Date (GNU date 才能解析, 失败自动跳过)
    get_date_header() {
        if [ "$HTTP_CLIENT" = "curl" ]; then
            curl -sI --connect-timeout 5 --max-time 8 "$1" 2>/dev/null \
                | sed -n 's/^[Dd]ate:[ ]*//p' | tr -d '\r'
        else
            wget -S --spider -T 8 "$1" 2>&1 \
                | sed -n 's/.*[Dd]ate:[ ]*//p' | tr -d '\r'
        fi
    }

    # 1) 阿里云网关自身时间 (与校验方同源, 最准)
    ms=$(date -u -d "$(get_date_header "$ENDPOINT")" +%s 2>/dev/null)

    # 2) 备用: 百度响应头时间
    if [ -z "$ms" ]; then
        ms=$(date -u -d "$(get_date_header "https://www.baidu.com")" +%s 2>/dev/null)
    fi

    # 3) 再备用: 毫秒级时间戳接口 (淘宝 → 苏宁)
    if [ -z "$ms" ]; then
        t=$(http_get "https://api.m.taobao.com/rest/api3.do?api=mtop.common.getTimestamp" \
            | grep -o '"t":"[0-9]*' | tr -d '"' | sed 's/t://')
        [ -z "$t" ] && t=$(http_get "https://f.m.suning.com/api/ct.do" \
            | grep -o '"currentTime":[0-9]*' | cut -d: -f2)
        case "$t" in
            [0-9]*) ms=$(( t / 1000 )) ;;
        esac
    fi

    # 统一用 awk 的 strftime 转成阿里云要求的 UTC 格式 (busybox awk 也支持)
    if [ -n "$ms" ]; then
        ts=$(TZ=UTC0 awk -v e="$ms" 'BEGIN{print strftime("%Y-%m-%dT%H:%M:%S", e) "Z"}')
        [ -n "$ts" ] && { printf '%s' "$ts"; return 0; }
    fi

    # 4) 全部失败 → 回退本地时间 (保持原行为)
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

url_encode() {
    printf '%s' "$1" | awk '
    BEGIN { for (i=1;i<256;i++) ord[sprintf("%c",i)]=i }
    {
        s=""
        for (i=1;i<=length($0);i++) {
            c=substr($0,i,1)
            if (c ~ /[A-Za-z0-9._~-]/) s=s c
            else s=s sprintf("%%%02X",ord[c])
        }
        print s
    }'
}

# ── 阿里云 RPC 签名: Base64(HMAC-SHA1(待签名串, Secret + "&")) ──
# 待签名串 = GET&%2F&URL编码(按参数名排序后的 k=v&k=v 串)
generate_signature() {
    params="$1"; secret="$2"
    sorted=$(printf '%s' "$params" | tr '&' '\n' | sort | tr '\n' '&' | sed 's/&$//')
    string="GET&%2F&$(url_encode "$sorted")"
    result=$(printf '%s' "$string" | "$MDDNS_BIN" -sha1 -hmac "${secret}&" -base64 2>&1)
    if [ -z "$result" ]; then
        log_err "签名失败: $MDDNS_BIN 无输出"
        return 1
    fi
    printf '%s' "$result"
}

send_request() {
    action="$1"; shift
    ts=$(get_utc_ts)
    nonce="$(date +%s)$$"
    all="Action=$action&Format=JSON&Version=2015-01-09&AccessKeyId=$ACCESS_KEY_ID&SignatureMethod=HMAC-SHA1&SignatureVersion=1.0&SignatureNonce=$nonce&Timestamp=$(url_encode "$ts")"
    for arg in "$@"; do all="$all&$arg"; done
    sig=$(generate_signature "$all" "$ACCESS_KEY_SECRET") || return 1
    http_get "${ENDPOINT}/?${all}&Signature=$(url_encode "$sig")"
}

# ── 响应检查: 空响应/含 Code 错误视为失败 ──
# 用法: check_api_error <result> ; 返回 0=正常, 1=失败(已记录日志)
check_api_error() {
    if [ -z "$1" ]; then
        log_err "API 无响应 (网络或认证失败)"
        return 1
    fi
    if printf '%s' "$1" | grep -q '"Code"'; then
        log_err "API 错误: $1"
        return 1
    fi
    return 0
}

get_record() {
    domain="$1"; sub="$2"; type="$3"
    log_info "查询记录: ${sub}.${domain} (${type})"
    result=$(send_request "DescribeDomainRecords" "DomainName=$domain" "RRKeyWord=$(url_encode "$sub")" "Type=$type")
    check_api_error "$result" || exit 1
    id=$(printf '%s' "$result" | grep -o '"RecordId":"[^"]*"' | head -1 | cut -d'"' -f4)
    val=$(printf '%s' "$result" | grep -o '"Value":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$id" ]; then
        log_ok "查询记录成功: ${sub}.${domain} (${type}) -> RecordId=${id}, Value=${val}"
        echo "$id $val"
    else
        log_err "查询记录失败: ${sub}.${domain} (${type}) 未找到记录"
    fi
}

add_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"
    log_info "添加记录: ${sub}.${domain} (${type}) -> ${val}"
    result=$(send_request "AddDomainRecord" "DomainName=$domain" "RR=$(url_encode "$sub")" "Type=$type" "Value=$(url_encode "$val")" "TTL=${ttl:-600}")
    if ! check_api_error "$result"; then
        exit 1
    fi
    if printf '%s' "$result" | grep -q '"RecordId"'; then
        log_ok "添加记录成功: ${sub}.${domain} (${type}) -> ${val}"
        echo "添加成功"
    else
        log_err "添加记录失败: ${sub}.${domain} (${type}) -> ${val}"
        log_err "API返回: $result"
        exit 1
    fi
}

update_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"; id="$6"
    log_info "更新记录: ${sub}.${domain} (${type}) -> ${val} (RecordId=${id})"
    result=$(send_request "UpdateDomainRecord" "RecordId=$id" "RR=$(url_encode "$sub")" "Type=$type" "Value=$(url_encode "$val")" "TTL=${ttl:-600}")
    if ! check_api_error "$result"; then
        exit 1
    fi
    if printf '%s' "$result" | grep -q '"RecordId"'; then
        log_ok "更新记录成功: ${sub}.${domain} (${type}) -> ${val} (RecordId=${id})"
        echo "更新成功"
    else
        log_err "更新记录失败: ${sub}.${domain} (${type}) -> ${val} (RecordId=${id})"
        log_err "API返回: $result"
        exit 1
    fi
}

delete_record() {
    domain="$1"; id="$2"
    log_info "删除记录: ${domain} (RecordId=${id})"
    result=$(send_request "DeleteDomainRecord" "RecordId=$id")
    if ! check_api_error "$result"; then
        exit 1
    fi
    if printf '%s' "$result" | grep -q '"RequestId"'; then
        log_ok "删除记录成功: ${domain} (RecordId=${id})"
        echo "删除成功"
    else
        log_err "删除记录失败: ${domain} (RecordId=${id})"
        log_err "API返回: $result"
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
