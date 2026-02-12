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

-- 初始化配置（确保模板有数据可用）
local function init_config()
    local section = uci:get("photopea", "config")
    if not section then
        section = uci:set("photopea", "config", "photopea")
    end
    -- 基础配置默认值
    uci:set("photopea", "config", "enabled", uci:get("photopea", "config", "enabled") or 0)
    uci:set("photopea", "config", "port", uci:get("photopea", "config", "port") or "8887")
    uci:set("photopea", "config", "token", uci:get("photopea", "config", "token") or generate_token())
    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map("photopea", _("Photopea"), 
    _("Photopea is online image editor.") .. "<br/>" ..
    _("Official website") .. ": <a href='www.Photopea.com' target='_blank'>Photopea</a>")

-- 调用独立状态模板
m:section(SimpleSection).template = "photopea/status"

-- 全局配置区域
s = m:section(TypedSection, "photopea", _("Basic Settings"))
s.addremove = false
s.anonymous = true

-- 启用开关
s:option(Flag, "enabled", _("Enable")).rmempty = false

-- 端口配置
o = s:option(Value, "port", _("Port"))
o.datatype = "port"
o.default = "8887"
o.rmempty = false
o.description = _("Access Service Port")

-- 解密密钥
o = s:option(Value, "token", _("Token"))
o.default = generate_token()
o.password = true
o.rmempty = true
o.description = _('Automatically generated 32-bit token');

-- 渲染表单
return m