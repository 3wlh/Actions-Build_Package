module(..., package.seeall)
local name = (...):match("%.([^%.]+)$")
module("luci.controller." .. name, package.seeall) 
local api = require("luci.model.cbi."..name..".api.download")

function index() 
    entry({"admin", "services", name}, call("action_index"), _("NapCat"), 90).dependent = true
    entry({"admin", "services", name, "download_exec"}, call("action_download")).leaf = true
    entry({"admin", "services", name, "app"}, call("app"), _("Settings"), 10).leaf = true 
end 

-- 二进制文件名与下载地址
local bin_file = "docker-web"
local cn_url = string.format("https://cnb.cool/3wlh/Build-File/-/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)
local default_url = string.format("https://github.com/3wlh/Build-Source/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index()
	if api.installed(bin_file) then
		app()
	else
		default_url = api.Get_Url(cn_url, default_url)
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

-- 检查端口是否被占用（true = 已占用, false = 空闲）
function is_port_in_use(port)
    local ok, s = pcall(nixio.bind, "0.0.0.0", port)
    if ok and s then
        s:close()
        return false   -- 绑定成功，说明没人占用
    end
    return true        -- 绑定失败，已被占用
end

-- 生成随机端口的函数
function get_port()
    math.randomseed(os.time())
    for _ = 1, 100 do
        local port = math.random(1024, 65535)
        if not is_port_in_use(port) then
            return port
        end
    end
    return nil
end

-- 输出错误日志
local errors = {}
function log_error(msg)
    local safe_msg = msg:gsub("'", "'\\''")
    table.insert(errors, safe_msg)
    local cmd = string.format("logger -t %s 'napcat error: %s'",name ,safe_msg )
    os.execute(cmd)
end
 
function sess_token() 
    local http = require "luci.http"
    local ubus = require "ubus"
    local sid = http.getcookie("sysauth") or
                http.getcookie("sysauth_http") or
                http.getcookie("sysauth_https") or
                http.getcookie("sid")
    if not sid then
        log_error("未获取到会话[ID]")
        return
    end
    local conn = ubus.connect()
    if not conn then
        log_error("未获取到[ubus]")
        return nil
    end
    local session_data = conn:call("session", "get", { ubus_rpc_session = sid })
    conn:close()
    if session_data and session_data.values and session_data.values.token then
        return session_data.values.token
    elseif session_data and session_data.token then
        return session_data.token
    end
    log_error("未获取到[token]")
    return nil
end

function get_data()
    return get_port(), sess_token()
end

function app()
    local port, token = get_data()  
    local docker = "/usr/share/napcat/docker.json"
    if #errors > 0 then
        luci.template.render(name.."/errlog", { errors = errors })
        return
    end
    local cmd = string.format("(/usr/sbin/%s -p %s -t %s -c %s >/dev/null &)", bin_file, port, token, docker) 
    if os.execute(cmd) then 
        luci.template.render(name.."/app", { 
            Port = port,
            Token = token
        }) 
    end
end