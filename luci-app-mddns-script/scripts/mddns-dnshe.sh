#!/bin/sh
#
# @provider: dnshe
# @display: DNSHE
# @key_field: api_key
# @secret_field: api_secret
#

log_info() { echo "[DNSHE] $1" >&2; }
log_ok()   { echo "[DNSHE] ✓ $1" >&2; }
log_err()  { echo "[DNSHE] ✗ $1" >&2; }

ENDPOINT="https://api005.dnshe.com/index.php"

# 用法: mddns-dnshe.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

API_KEY="${KEY:-${DNSHE_API_KEY}}"
API_SECRET="${SECRET:-${DNSHE_API_SECRET}}"

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
    echo "错误: 请提供 key 和 secret" >&2
    exit 1
fi

TTL="${TTL:-600}"

# 检测 HTTP 客户端
if command -v curl >/dev/null 2>&1; then
    HTTP_CLIENT="curl"
elif command -v wget >/dev/null 2>&1; then
    HTTP_CLIENT="wget"
else
    echo "错误: 需要 curl 或 wget" >&2
    exit 1
fi

# URL 编码 (RFC 3986)
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

# HTTP GET (带认证头)
http_get() {
    if [ "$HTTP_CLIENT" = "curl" ]; then
        curl -s --connect-timeout 5 --max-time 15 -H "X-API-Key: $API_KEY" -H "X-API-Secret: $API_SECRET" "$1"
    else
        wget -q -O - --timeout=15 --tries=1 --header="X-API-Key: $API_KEY" --header="X-API-Secret: $API_SECRET" "$1"
    fi
}

# HTTP POST (JSON body, 带认证头)
http_post() {
    if [ "$HTTP_CLIENT" = "curl" ]; then
        curl -s --connect-timeout 5 --max-time 15 -X POST \
            -H "X-API-Key: $API_KEY" \
            -H "X-API-Secret: $API_SECRET" \
            -H "Content-Type: application/json" \
            -d "$2" "$1"
    else
        wget -q -O - --timeout=15 --tries=1 \
            --header="X-API-Key: $API_KEY" \
            --header="X-API-Secret: $API_SECRET" \
            --header="Content-Type: application/json" \
            --method=POST \
            --body-data="$2" \
            "$1"
    fi
}

# 查找子域名 ID 和记录名
# DNSHE 模型: rootdomain + subdomain + record_name (三级)
# MDDNS 模型: domain + sub (两级), full_domain = sub.domain
# 本函数从 full_domain 中自动定位 DNSHE 已注册的子域名:
#   1. 提取 full_domain 最后两部分作为 rootdomain
#   2. 列出该 rootdomain 下的所有子域名
#   3. 找到 full_domain 的父域 (full_domain == 子域名 或 full_domain 以 .子域名 结尾)
# 输出: "subdomain_id record_name" (record_name 为 "@" 表示子域名本身)
find_subdomain_id() {
    domain="$1"; sub="$2"
    # sub 为 "@" 或空时, full_domain = domain 本身 (表示子域名根记录)
    if [ "$sub" = "@" ] || [ -z "$sub" ]; then
        full_domain="$domain"
    else
        full_domain="${sub}.${domain}"
    fi
    log_info "查找子域名: $full_domain"

    # rootdomain = full_domain 的最后两部分 (如 cc.cd)
    rootdomain=$(printf '%s' "$full_domain" | awk -F. '{print $(NF-1)"."$NF}')

    enc_root=$(url_encode "$rootdomain")
    url="${ENDPOINT}?m=domain_hub&endpoint=subdomains&action=list&rootdomain=${enc_root}&per_page=500"
    result=$(http_get "$url")

    if ! printf '%s' "$result" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_err "查找子域名失败: $result"
        return 1
    fi

    # 用 awk 遍历子域名列表, 找到 full_domain 的父域
    # 用 index() 做字面量替换 "},{" → "}\n{" (兼容 BusyBox awk, 不依赖 RS 正则)
    # 匹配规则: full_domain == 子域名的 full_domain → record_name="@"
    #           full_domain 以 ".子域名的 full_domain" 结尾 → record_name=full_domain
    match=$(printf '%s' "$result" | awk -v fd="$full_domain" '
    {
        all = all $0
    }
    END {
        old = "},{"
        new = "}\n{"
        while ((pos = index(all, old)) > 0) {
            all = substr(all, 1, pos-1) new substr(all, pos + length(old))
        }
        n = split(all, lines, "\n")
        for (i = 1; i <= n; i++) {
            line = lines[i]
            if (match(line, /"id":[0-9]+/)) {
                id = substr(line, RSTART+5, RLENGTH-5)
            } else { continue }
            if (match(line, /"full_domain":"[^"]*"/)) {
                sfd = substr(line, RSTART+15, RLENGTH-16)
            } else { continue }
            if (fd == sfd) {
                print id " @"
                exit
            }
            suffix = "." sfd
            if (length(fd) > length(suffix) && substr(fd, length(fd)-length(suffix)+1) == suffix) {
                print id " " fd
                exit
            }
        }
    }')

    if [ -z "$match" ]; then
        log_err "未找到子域名: $full_domain (请先在 DNSHE 注册该子域名)"
        log_info "API 响应: $result"
        return 1
    fi

    sid=$(printf '%s' "$match" | cut -d' ' -f1)
    rname=$(printf '%s' "$match" | cut -d' ' -f2)
    log_ok "找到子域名: $full_domain (ID=$sid, Name=$rname)"
    echo "$match"
}

# 查找 DNS 记录 (按 name + type 精确匹配)
# record_name 为 "@" 时同时匹配 "@" 和完整域名
find_dns_record() {
    sid="$1"; target_type="$2"; record_name="$3"
    log_info "查找 DNS 记录: name=$record_name, type=$target_type"

    url="${ENDPOINT}?m=domain_hub&endpoint=dns_records&action=list&subdomain_id=$sid"
    result=$(http_get "$url")

    if ! printf '%s' "$result" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_err "查找 DNS 记录失败: $result"
        return 1
    fi

    # 匹配同一对象内同时含 "name":"xxx" 和 "type":"yyy"
    # [^}]* 结尾捕获完整对象内容 (含 type 之后的 content 字段); [^}]* 确保不跨对象边界
    line=$(printf '%s' "$result" | grep -o "\"id\":[0-9]*[^}]*\"name\":\"$record_name\"[^}]*\"type\":\"$target_type\"[^}]*" | head -1)
    if [ -z "$line" ]; then
        line=$(printf '%s' "$result" | grep -o "\"id\":[0-9]*[^}]*\"type\":\"$target_type\"[^}]*\"name\":\"$record_name\"[^}]*" | head -1)
    fi
    # record_name 为 "@" 时, DNS 记录的 name 可能是完整域名, 回退取第一条 type 匹配
    if [ -z "$line" ] && [ "$record_name" = "@" ]; then
        line=$(printf '%s' "$result" | grep -o "\"id\":[0-9]*[^}]*\"type\":\"$target_type\"[^}]*" | head -1)
    fi
    if [ -z "$line" ]; then
        log_info "未找到记录: name=$record_name, type=$target_type"
        return 0
    fi

    rid=$(printf '%s' "$line" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    content=$(printf '%s' "$line" | grep -o '"content":"[^"]*"' | head -1 | sed 's/.*:"\([^"]*\)".*/\1/')

    log_ok "找到记录: ID=$rid, Content=$content"
    echo "$rid $content"
}

# 创建 DNS 记录
create_dns_record() {
    sid="$1"; rtype="$2"; content="$3"; ttl="$4"; name="$5"
    log_info "创建记录: name=$name, type=$rtype, content=$content, ttl=$ttl"

    data="{\"subdomain_id\":$sid,\"type\":\"$rtype\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl}"
    url="${ENDPOINT}?m=domain_hub&endpoint=dns_records&action=create"
    result=$(http_post "$url" "$data")

    if printf '%s' "$result" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_ok "创建记录成功: name=$name, type=$rtype, content=$content"
        return 0
    else
        log_err "创建记录失败: $result"
        return 1
    fi
}

# 更新 DNS 记录
update_dns_record() {
    rid="$1"; rtype="$2"; content="$3"; ttl="$4"
    log_info "更新记录: ID=$rid, type=$rtype, content=$content, ttl=$ttl"

    data="{\"id\":$rid,\"type\":\"$rtype\",\"content\":\"$content\",\"ttl\":$ttl}"
    url="${ENDPOINT}?m=domain_hub&endpoint=dns_records&action=update"
    result=$(http_post "$url" "$data")

    if printf '%s' "$result" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_ok "更新记录成功: ID=$rid, type=$rtype, content=$content"
        return 0
    else
        log_err "更新记录失败: $result"
        return 1
    fi
}

# 删除 DNS 记录
delete_dns_record() {
    rid="$1"
    log_info "删除记录: ID=$rid"

    data="{\"id\":$rid}"
    url="${ENDPOINT}?m=domain_hub&endpoint=dns_records&action=delete"
    result=$(http_post "$url" "$data")

    if printf '%s' "$result" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        log_ok "删除记录成功: ID=$rid"
        return 0
    else
        log_err "删除记录失败: $result"
        return 1
    fi
}

case "$ACTION" in
    get)
        match=$(find_subdomain_id "$DOMAIN" "$SUB")
        if [ -z "$match" ]; then
            exit 1
        fi
        sid=$(printf '%s' "$match" | cut -d' ' -f1)
        rname=$(printf '%s' "$match" | cut -d' ' -f2)
        find_dns_record "$sid" "$TYPE" "$rname"
        ;;
    add)
        match=$(find_subdomain_id "$DOMAIN" "$SUB")
        if [ -z "$match" ]; then
            exit 1
        fi
        sid=$(printf '%s' "$match" | cut -d' ' -f1)
        rname=$(printf '%s' "$match" | cut -d' ' -f2)
        create_dns_record "$sid" "$TYPE" "$IP" "$TTL" "$rname"
        ;;
    update)
        update_dns_record "$RECORD_ID" "$TYPE" "$IP" "$TTL"
        ;;
    delete)
        delete_dns_record "$RECORD_ID"
        ;;
    *)
        echo "用法: $0 {get|add|update|delete} <参数...>" >&2
        exit 1
        ;;
esac
