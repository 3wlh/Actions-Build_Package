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
    return key
end

-- 初始化配置（确保模板有数据可用）
local function init_config()
    local section = uci:get("napcatapi", "config")
    if not section then
        section = uci:set("napcatapi", "config", "napcatapi")
    end
    -- 基础配置默认值
    uci:set("napcatapi", "config", "enabled", uci:get("napcatapi", "config", "enabled") or 0)
    uci:set("napcatapi", "config", "port", uci:get("napcatapi", "config", "port") or "5663")
    uci:set("napcatapi", "config", "path_config", uci:get("napcatapi", "config", "path_config") or "/etc/napcatapi")
    uci:set("napcatapi", "config", "pwd_config", uci:get("napcatapi", "config", "pwd_config") or generate_key())
    uci:set("napcatapi", "config", "online_config", uci:get("napcatapi", "config", "online_config") or "http[s]://")
    uci:set("napcatapi", "config", "token", uci:get("napcatapi", "config", "token") or generate_token())
    -- Token初始化
    -- local token = uci:get("napcatapi", "config", "token")
    -- if not token or token ~= 32 then
        -- token = generate_token()
        -- uci:set("napcatapi", "config", "token", token)
        -- pcall(function() uci:save("napcatapi") end)
        -- pcall(function() uci:commit("napcatapi") end)
    -- end
    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map("napcatapi", _("NapCat API"), 
    _("NapCat Robot call the API configuration page.") .. "<br/>" ..
    _("Official reference") .. ": <a href='https://github.com/3wlh/' target='_blank'>NapCat API</a>")

-- 调用独立状态模板
m:section(SimpleSection).template = "napcatapi/status"

-- 全局配置区域
s = m:section(TypedSection, "napcatapi", _("Basic Settings"))
s.addremove = false
s.anonymous = true

-- 启用开关
s:option(Flag, "enabled", _("Enable")).rmempty = false

-- 端口配置
o = s:option(Value, "port", _("Port"))
o.datatype = "port"
o.default = "5663"
o.rmempty = false
o.description = _("Web Service Port")

-- 配置文件路径
o = s:option(Value, "path_config", _("Config path"))
o.default = "/etc/napcatapi"
o.rmempty = true
o.datatype = "string"
o.description = _('Configuration File Storage Path');

-- 解密密钥
o = s:option(Value, "pwd_config", _("Decrypt KEY"))
o.default = generate_key()
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