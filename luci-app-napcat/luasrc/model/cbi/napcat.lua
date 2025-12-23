-- 必须先导入翻译模块（核心修复！）
local i18n = require "luci.i18n"
local _ = i18n.translate

-- 导入 CBI 核心模块
local m, s, o
local uci = require("luci.model.uci").cursor()

-- 初始化 Map（指定翻译域）
m = Map("napcat", _("NapCat QQ Bot 配置"), 
    _("基于 Docker 的 NapCat QQ 机器人配置，需提前安装 Docker 环境"))
m:chain("luci")  -- 关联 LuCI 配置域，确保翻译生效

-- 基本配置段
s = m:section(TypedSection, "main", _("基本配置"))
s.anonymous = true
s.addremove = false

-- Docker 镜像地址
o = s:option(Value, "image", _("镜像地址"))
o.default = "docker.cnb.cool/3wlh/docker-sync/mlikiowa-napcat-docker"
o.rmempty = false
o.description = _("NapCat Docker 镜像地址，请勿随意修改")

-- 容器名称
o = s:option(Value, "container_name", _("容器名称"))
o.default = "napcat"
o.rmempty = false

-- 独立启动开关
o = s:option(Flag, "enable", _("启用 NapCat 服务"), _("关闭后将停止容器且开机不启动"))
o.default = "1"
o.rmempty = false

-- 3个端口变量
o = s:option(Value, "main_port", _("主服务端口"), _("NapCat 核心服务端口"))
o.default = "3000"
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "api_port", _("API 接口端口"), _("NapCat API 调用端口"))
o.default = "3001"
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "ws_port", _("WebSocket 端口"), _("NapCat 实时通信端口"))
o.default = "3002"
o.datatype = "port"
o.rmempty = false

-- 网络模式选择
o = s:option(ListValue, "network_mode", _("容器网络模式"))
o:value("bridge", _("桥接模式（默认）"))
o:value("host", _("主机模式（性能更好）"))
o:value("none", _("无网络（仅测试用）"))
o.default = "bridge"
o.description = _("主机模式无需映射端口，直接使用路由器端口")

-- 自动启动（关联启动开关）
o = s:option(Flag, "autostart", _("开机自动启动"), _("需先启用服务才生效"))
o.default = "1"
o.rmempty = false
o:depends("enable", "1")

-- 独立的目录配置段
s = m:section(TypedSection, "directory", _("目录配置"), _("数据持久化相关目录"))
s.anonymous = true
s.addremove = false

-- 2个目录变量（独立分段）
o = s:option(Value, "data_dir", _("数据存储目录"), _("存放 NapCat 配置/日志/数据"))
o.default = "/etc/napcat/data"
o.rmempty = false
o.description = _("主机侧目录，会自动创建")

o = s:option(Value, "config_dir", _("配置文件目录"), _("存放自定义配置文件"))
o.default = "/etc/napcat/config"
o.rmempty = false
o.description = _("主机侧目录，会自动创建")

-- 高级配置段（仅保留环境变量）
s = m:section(TypedSection, "advanced", _("高级配置"))
s.anonymous = true
s.addremove = false

-- 环境变量（仅保留此项）
o = s:option(Value, "env", _("环境变量"), _("多个变量用逗号分隔，如 KEY1=VAL1,KEY2=VAL2"))
o.description = _("NapCat 运行所需的环境变量，根据需要配置")

return m