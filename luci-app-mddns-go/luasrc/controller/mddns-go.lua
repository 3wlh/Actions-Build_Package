module(..., package.seeall)
local name = (...):match("%.([^%.]+)$")
local api = require("luci.model.cbi."..name..".api.download")

function index()
	entry({"admin", "services", name}, firstchild(), _("MultiDDNS"), 90).dependent = true
	entry({"admin", "services",name.."_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", name, "settings"}, cbi(name.."/settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "parse"}, call("template", "parse"), _("Parse"), 20).leaf = true
	entry({"admin", "services", name, "logs"}, call("template", "logs"), _("Logs"), 30).leaf = true
end

-- 二进制文件名与下载地址
local bin_file = "mddns-go"
local cn_url = "https://cnb.cool/3wlh/Build-File/-/releases/download//GitHub-Actions_MDDNS/MDDNS-linux-%s"
local default_url = "https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_MDDNS/MDDNS-linux-%s"

function Get_Url()
	return cnb_url
end

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index()
	if api.installed(bin_file) then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", name, "settings"))
	else
		default_url= api.Get_Url(cn_url, default_url)
		local info = api.arch_info(bin_file, default_url)
		luci.template.render(name.."/download", {
			Name = name,
			arch = info.arch,
			pkg_arch = info.pkg_arch,
			bin_name = info.bin_name,
			bin_dir = info.bin_path,
			bin_url = info.bin_url
		})
	end
end

-- 启动下载
function action_download()
	local info = api.arch_info(bin_file, default_url)
	local total = tonumber(luci.http.formvalue("total"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(api.download(info.bin_path, info.bin_url, total))
end

function template(index)
	luci.template.render(name.."/"..index, { 
		Name = name, 
	})
end

function Run_status()
	luci.http.prepare_content("application/json")
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get(name, "config", "port"))
	local token = uci:get(name, "config", "token")
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
		port = (port or 5063),
		token = (token or "")
	}
	luci.http.write_json(status)
end

