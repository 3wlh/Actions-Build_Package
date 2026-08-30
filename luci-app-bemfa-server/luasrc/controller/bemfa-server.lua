module(..., package.seeall)
local name = (...):match("%.([^%.]+)$")
module("luci.controller."..name, package.seeall)
local api = require("luci.model.cbi."..name..".api.download")

function index()
	-- 菜单始终注册 (二进制检查在 action_index 实时执行, 避免菜单缓存导致下载后不刷新)
	entry({"admin", "services", name}, call("action_index"), _("Bemfa"), 90).dependent = true
	entry({"admin", "services",name.."_status"}, call("Run_status")).leaf = true
	entry({"admin", "services", name, "download_exec"}, call("action_download")).leaf = true
	-- 注册文件读写的 RPC 接口
    entry({"admin", "services", name.."_read"}, call("Read_File"), nil).leaf = true
    entry({"admin", "services", name.."_save"}, call("Save_File"), nil).leaf = true
    entry({"admin", "services", name.."_logs"}, call("exec_log"), nil).leaf = true
	-- 注册菜单 --
	entry({"admin", "services", name, "settings_cbi"}, cbi(name.."/settings")).leaf = true
	entry({"admin", "services", name, "settings"}, call("action_index", "settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "edit"}, call("action_index", "edit"), _("Edit"), 20).leaf = true
	entry({"admin", "services", name, "logs"}, call("action_index", "logs"), _("Logs"), 30).leaf = true
end

local EXEC_LOG = string.format("/tmp/%s.log", name)
local TARGET_FILE = string.format("/etc/%s/devices.json", name)


-- 二进制文件名与下载地址
local bin_file = name
local cn_url = string.format("https://cnb.cool/3wlh/Build-File/-/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)
local default_url = string.format("https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index(index)
	-- 取 URL 最后一段 "parse" / "logs"
	local index_name = luci.dispatcher.context.path[#luci.dispatcher.context.path]
	if api.installed(bin_file) then
		-- if index_name == "settings" then
		if index_name:match("settings") or index == nil then
			luci.http.redirect(luci.dispatcher.build_url("admin", "services", name, "settings_cbi"))
			return
		end	
		luci.template.render(name.."/" .. index_name, {
            Name = name,
        })
	else
		local info = api.arch_info(bin_file, api.Get_Url(cn_url, default_url))
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
	local url  = luci.http.formvalue("url")
	local path = luci.http.formvalue("path")
	--local info = api.arch_info(bin_file, file_url)
	local total = tonumber(luci.http.formvalue("total"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(api.download(path, url, total))
end

function Run_status()
	luci.http.prepare_content("application/json")
	local uci  = require "luci.model.uci".cursor()
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
	}
	luci.http.write_json(status)
end

-- 读取单个文件内容
function Read_File()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    -- 安全检查：文件是否存在
    if not fs.access(TARGET_FILE, "r") then
        http.write_json({ code = 1, msg = "File not found" })
        return
    end

    local content = fs.readfile(TARGET_FILE)
    if content then
        http.write_json({ code = 0, data = content })
    else
        http.write_json({ code = 1, msg = "Failed to read file" })
    end
end

-- 保存单个文件内容
function Save_File()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local content = http.formvalue("content")
    -- 安全检查：内容非空 + 文件可写
    if not content or not fs.access(TARGET_FILE, "w") then
        http.write_json({ code = 1, msg = "File not writable" })
        return
    end
    local res = fs.writefile(TARGET_FILE, content)

    if res then
        http.write_json({ code = 0, msg = "Save success" })
    else
        http.write_json({ code = 1, msg = "Save Failed." })
    end
end

-- 获取日志
local fs = require "nixio.fs"
function exec_log()
    luci.http.header("Content-Type", "text/plain; charset=utf-8")
    luci.http.header("Cache-Control", "no-cache")   -- 防止缓存

    local content = fs.readfile(EXEC_LOG)
    if content then
        luci.http.write(content)
    else
        luci.http.write("")
    end
end