local name = debug.getinfo(1, "S").source:match("/([^/]+)/[^/]+$")
local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"

-- 翻译函数
local function _(s)
    return translate(s)
end

-- 初始化配置（确保模板有数据可用）
local function init_config()
    local section = uci:get(name, "config")
    if not section then
        section = uci:set(name, "config", "main")
    end
    -- 基础配置默认值
    uci:set(name, "config", "enabled", uci:get(name, "config", "enabled") or 0)
    uci:set(name, "config", "key", uci:get(name, "config", "key") or "")
    uci:set(name, "config", "topic", uci:get(name, "config", "topic") or "")
    uci:set(name, "config", "msg", uci:get(name, "config", "msg") or "on")

    return
end

-- 初始化配置
init_config()

local m, s, o
m = Map(name, _("Configuration"), 
    _("A professional IoT device access and management platform, providing stable and reliable persistent TCP connections and MQTT protocol support.")
    .. "<br/>" .. _("Official reference") .. ": <a href='https://cloud.bemfa.com/tcp/index.html' target='_blank'>Bemfa</a>")

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

-- 配置令牌
o = s:option(Value, "key", _("UserKey"))
o.password = true
o.rmempty = true
o.description = _("Please enter your user token.")

-- 配置订阅
o = s:option(Value, "topic", _("Topic"))
o.rmempty = true
o.datatype = "string"
o.description = _('Please enter the subscription topics, separated by |.');

-- 配置消息
o = s:option(Value, "msg", _("Msg"))
o.default = "on"
o.rmempty = true
o.description = _('Filter keywords (empty = no filter; if set, only messages matching any keyword are kept; separate with |)');

-- 渲染表单
return m