local name=debug.getinfo(1, "S").source:match("/([^/]+)/[^/]+$")
local uci = require "luci.model.uci".cursor()

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
    -- 获取eth0 MAC（优先ip命令）
    local cmd="ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'"
    local mac = luci.sys.exec(cmd):gsub("%s+", "")
    -- 备用方法
    if not mac or mac == "" then
        mac = luci.sys.exec("cat /sys/class/net/eth0/address 2>/dev/null"):gsub("%s+", "")
    end
    -- local mac = luci.util.exec("ethtool -P eth0 | grep -o '[0-9a-f:]\{17\}' 2>/dev/null")
    local key = ""
    if mac and mac ~= "" then
        key = luci.sys.exec(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", mac)):gsub("%s+", "")
    end
    return mac, key
end

local mac, key = generate_key()

-- 初始化配置（确保模板有数据可用）
local function init_config()
    local section = uci:get(name, "config")
    if not section then
        section = uci:set(name, "config", "main")
    end
    -- 基础配置默认值
    uci:set(name, "config", "enabled", uci:get(name, "config", "enabled") or 0)
    uci:set(name, "config", "port", uci:get(name, "config", "port") or "5663")
    uci:set(name, "config", "path_config", uci:get(name, "config", "path_config") or "/etc/napcatapi")
    uci:set(name, "config", "pwd_config", uci:get(name, "config", "pwd_config") or key)
    uci:set(name, "config", "online_config", uci:get(name, "config", "online_config") or "http[s]://")
    uci:set(name, "config", "token", uci:get(name, "config", "token") or generate_token())
    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map(name, _("Configuration"), 
    _("NapCat Robot call the API configuration page.") .. "<br/>" ..
    _("Official reference") .. ": <a href='https://github.com/3wlh/' target='_blank'>NapCat API</a>" ..
    (mac ~= "" and "<br><b>Mac: </b> <span style='color:#3498db;'>" .. mac .. "</span>" or "")..
    (key ~= "" and "<br><b>Key: </b> <span style='color:#e74c3c;'>" .. key .. "</span>" or ""))

m.apply_on_parse = true -- 解析阶段立即写入配置文件
m.on_after_commit = function(self)
    -- os.execute("/etc/init.d/"..name.." restart &")
end

-- 调用独立状态模板
s = m:section(SimpleSection)
s.template = name.."/status"
s.Name = name

-- 全局配置区域
s = m:section(TypedSection, "main", _("Basic Settings"))
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
o.default = "/etc/"..name
o.rmempty = true
o.datatype = "string"
o.description = _('Configuration File Storage Path');

-- 解密密钥
o = s:option(Value, "pwd_config", _("Decrypt KEY"))
o.default = key
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