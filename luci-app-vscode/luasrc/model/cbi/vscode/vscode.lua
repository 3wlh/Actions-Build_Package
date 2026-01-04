-- 核心依赖（全量容错）
local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"

-- 翻译函数兜底
local function _(s)
    return translate(s)
end

local function init_config()
    local section = uci:get("vscode", "config")
    if not section then
        section = uci:set("vscode", "config", "vscode")
    end
    -- 基础配置默认值
    uci:set("vscode", "config", "enabled", uci:get("vscode", "config", "enabled") or 0)
    uci:set("vscode", "config", "port", uci:get("vscode", "config", "port") or "5663")
    uci:set("vscode", "config", "path_config", uci:get("vscode", "config", "path_config") or "/")
    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map("vscode", _("VSCode"), 
    _(".") .. "<br/>" ..
    _("Official reference") .. ": <a href='https://github.com/3wlh/' target='_blank'>VSCode</a>")

-- 调用独立状态模板
m:section(SimpleSection).template = "napcatapi/status"

-- 全局配置区域
s = m:section(TypedSection, "vscode", _("Basic Settings"))
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

-- 渲染表单
return m