local name = "napcat"
module("luci.controller." .. name, package.seeall) 
local api = require "luci.model.cbi."..name..".api.download"

-- 二进制名与下载源 (action_index 渲染 + action_download 回退共用)
local bin_file = "docker-web"
local download_url = "https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_docker_web/" .. bin_file

function index() 
    entry({"admin", "services", name}, call("action_index"), _("NapCat"), 90).dependent = true
    entry({"admin", "services", name, "download_exec"}, call("action_download")).leaf = true
    entry({"admin", "services", name, "app"}, call("app"), _("Settings"), 10).leaf = true 
end 

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index()
	if api.installed(bin_file) then
		luci.http.redirect(luci.dispatcher.build_url("admin", "system", name, "settings"))
	else
		local info = api.arch_info(bin_file, download_url)
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

-- 下载二进制: 服务端用控制器常量推导路径/URL, 调 api.download
function action_download()
	local info = api.arch_info(bin_file, download_url)
	luci.http.prepare_content("application/json")
	luci.http.write_json(api.download(info.bin_path, info.bin_url))
end
-- 输出错误日志
local errors = {}
function log_error(msg)
    local safe_msg = msg:gsub("'", "'\\''")
    table.insert(errors, safe_msg)
    local cmd = string.format("logger -t %s 'napcat error: %s'",name ,safe_msg )
    os.execute(cmd)
end

function get_port() 
    math.randomseed(os.time()) 
    for _ = 1, 10 do 
        local port = math.random(1024, 65535) 
        local cmd = string.format("netstat -tunl | grep -qw :%d", port) 
        local ret = os.execute(cmd) 
        if ret ~= 0 then 
            return port
        end 
    end
    log_error("未获取可用到[Port]")
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
    local docker = "/usr/share/napcat/docker.json" 
    local cmd = string.format("/usr/sbin/%s -p %s -t %s -c %s >/dev/null &", bin_file, port, token, docker) 
    if os.execute(cmd) then 
        luci.template.render(name.."/app", { 
            Port = port,
            -- Token = token
        }) 
    end
end