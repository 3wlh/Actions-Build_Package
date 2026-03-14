local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"

-- 翻译函数
local function _(s)
    return translate(s)
end

-- 生成32位Token
local function generate_token()
    math.randomseed(os.time() + os.clock() * 1000000)
    local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    local result = ""
    local charsLen = #chars
    -- 循环生成32个随机字符
    for i = 1, 32 do
        -- 随机取字符集中的一个字符
        local randomIdx = math.random(1, charsLen)
        result = result .. string.sub(chars, randomIdx, randomIdx)
    end
    return result
end

-- 生成解密密钥（Key）的函数（保留原有逻辑，无错误）
local function generate_key()
    local mac = nil
    -- 获取eth0 MAC
    local ip_cmd = io.popen("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if ip_cmd then
        mac = ip_cmd:read("*a"):gsub("%s+", "")
        ip_cmd:close()
    end
    -- 备用取 MAC
    if not mac or mac == "" then
        local mac_file = io.open("/sys/class/net/eth0/address", "r")
        if mac_file then
            mac = mac_file:read("*a"):gsub("%s+", "")
            mac_file:close()
        end
    end
    -- 生成解密Key
    local key = ""
    if mac and mac ~= "" then
        local md5_cmd = io.popen("echo -n '" .. mac .. "' | md5sum | awk '{print $1}' | cut -c9-24")
        if md5_cmd then
            key = md5_cmd:read("*a"):gsub("%s+", "")
            md5_cmd:close()
        end
    end
    -- 同时返回MAC和解密Key
    return mac, key 
end


local device_mac, decrypt_key = generate_key()

-- 初始化配置（确保模板有数据可用）
local function init_config()
    local section = uci:get("dnsto", "config")
    if not section then
        section = uci:set("dnsto", "config", "dnsto")
    end
    -- 基础配置默认值
    uci:set("dnsto", "config", "enabled", uci:get("dnsto", "config", "enabled") or 0)
    uci:set("dnsto", "config", "port", uci:get("dnsto", "config", "port") or "5063")
    uci:set("dnsto", "config", "path_config", uci:get("dnsto", "config", "path_config") or "/etc/dnsto")
    uci:set("dnsto", "config", "pwd_config", uci:get("dnsto", "config", "pwd_config") or decrypt_key)
    uci:set("dnsto", "config", "online_config", uci:get("dnsto", "config", "online_config") or "http[s]://")
    uci:set("dnsto", "config", "token", uci:get("dnsto", "config", "token") or generate_token())
    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map("dnsto", _("DNSTO Settings"), 
    _("A lightweight DDNS automatic update tool that supports multiple DNS service providers.") .. "<br/>" ..  
    (device_mac ~= "" and "<br><b>MAC: </b> <span style='color:#3498db;'>" .. device_mac .. "</span>" or "") .. 
    (decrypt_key ~= "" and "<br><b>Key: </b> <span style='color:#e74c3c;'>" .. decrypt_key .. "</span>" or "")) .. 
    "<br/>" .. _("Official reference") .. ": <a href='https://github.com/3wlh/' target='_blank'>DNSTO</a>")
    

-- 调用独立状态模板
m:section(SimpleSection).template = "dnsto/status"

-- 全局配置区域
s = m:section(TypedSection, "dnsto", _("Basic Settings"))
s.addremove = false
s.anonymous = true

-- 启用开关
s:option(Flag, "enabled", _("Enable")).rmempty = false

-- 端口配置
o = s:option(Value, "port", _("Port"))
o.datatype = "port"
o.default = "5063"
o.rmempty = false
o.description = _("Web Service Port")

-- 配置文件路径
o = s:option(Value, "path_config", _("Config Path"))
o.default = "/etc/dnsto"
o.rmempty = true
o.datatype = "string"
o.description = _('Configuration File Storage Path');

-- 解密密钥
o = s:option(Value, "pwd_config", _("Decrypt KEY"))
o.default = decrypt_key
o.password = true
o.rmempty = true
o.description = _('Decryption Key[Auto MAC Generate]');

-- 在线配置URL
o = s:option(Value, "online_config", _("Online Config URL"))
o.default = "http[s]://"
o.rmempty = true
o.datatype = "string"
o.description = _('URL for online configuration pull');

-- 渲染表单
return m