module(..., package.seeall)
local name = (...):match("%.([^%.]+)$") 
module("luci.controller."..name, package.seeall) 
local api = require("luci.model.cbi."..name..".api.download")

function index()
    entry({"admin", "system", name},  call("action_index"), _("在线配置"), 90).dependent = true
    entry({"admin", "system", name, "run"}, call("exec_run"), nil).leaf = true
    entry({"admin", "system", name, "stop"}, call("exec_stop"), nil).leaf = true
    entry({"admin", "system", name, "download_exec"}, call("action_download")).leaf = true
    -- 注册菜单 --
    entry({"admin", "system", name, "settings_cbi"}, cbi(name.."/settings")).leaf = true
    entry({"admin", "system", name, "settings"}, call("action_index", "settings"), _("Settings"), 10).leaf = true
    entry({"admin", "system", name, "execute"},call("action_index", "execute"), _("执行命令"), 20).leaf = true
    
end

-- 二进制名称与下载地址
local bin_file = "sseconsole"
local cn_url = string.format("https://cnb.cool/3wlh/Build-File/-/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)
local default_url = string.format("https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_%s/%s-%%s",bin_file ,bin_file)

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index(index)
	-- 取 URL 最后一段 "parse" / "logs"
	local index_name = luci.dispatcher.context.path[#luci.dispatcher.context.path]
	if api.installed(bin_file) then
		-- if index_name == "settings" then
		if index_name:match("settings") or index == nil then
			luci.http.redirect(luci.dispatcher.build_url("admin", "system", name, "settings_cbi"))
			return
		end	
		exec_cmd()
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

-- 启动下载(若无进程) + 返回状态 (前端轮询同一接口)
function action_download()
	local url  = luci.http.formvalue("url")
	local path = luci.http.formvalue("path")
	local total = tonumber(luci.http.formvalue("total"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(api.download(path, url, total))
end

-- 输出错误日志
local errors = {}
function log_msg(msg)
    table.insert(errors, msg)
    nixio.syslog("info",string.format("%s: %s", name,msg))
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



-- 获取登录token
function sess_token() 
    local sid = nil
    local cookie_sid = {"sysauth", "sysauth_http", "sysauth_https", "sid"}
    for _, name in ipairs(cookie_sid) do
        sid = luci.http.getcookie(name)
        if sid then break end
    end
    if not sid then
        log_msg("未获取到会话[ID]")
        return
    end
    local conn = ubus.connect()
    if not conn then
        log_msg("无法连接[ubus]")
        return nil
    end
    local session_data = conn:call("session", "get", { ubus_rpc_session = sid })
    conn:close()
    if session_data and session_data.values and session_data.values.token then
        return session_data.values.token
    elseif session_data and session_data.token then
        return session_data.token
    end
    return nil
end

-- 生成位随机字符（默认:32）
local function generate_string(len)
    math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    local result = ""
    local charsLen = #chars
    len = len or 32
    for i = 1, len do
        -- 随机取字符集中的一个字符
        local randomIdx = math.random(1, charsLen)
        result = result .. string.sub(chars, randomIdx, randomIdx)
    end
    return result
end

-- 生成解密密钥（Key）的函数
local function get_key()
    -- 获取eth0 MAC（优先ip命令）
    local mac = luci.util.exec("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if mac then
        mac = mac:gsub("%s+", "")
    end
    -- 备用方法
    if not mac or mac == "" then
        local mac = luci.util.exec("cat /sys/class/net/eth0/address 2>/dev/null")
        if mac then
            mac = mac:gsub("%s+", "")
        end
    end
    local safe_mac = mac:gsub("'", "'\\''")
    local key = luci.util.exec(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", safe_mac))
    if key then
        key = key:gsub("%s+", "")
    end
    return mac, key
end

function get_data()
    return generate_string(5), get_port(), sess_token()
end

function exec_cmd()
    local example, port, token = get_data()  
    if #errors > 0 then
        luci.template.render(name.."/errlog", { errors = errors })
        return
    end
    local cmd = string.format("/usr/sbin/sseconsole -n %s -p %s -t %s >/dev/null &", example, port, token)
    if luci.sys.call(cmd) == 0 then
        os.execute("sleep 0.5")
        if is_port_in_use(port) then
            luci.template.render(name.."/exec", {
                Name = name,
                Port = port,
                Example = example,
                --Token = token
            })
        else
            log_msg("程序未运行")
            luci.template.render(name.."/errlog", { errors = errors })
        end
    end
end

local function shell_quote(s)
    s = s or ""
    return (s:gsub("'", "'\\''"))
end

local function get_config()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = shell_quote(uci:get(name, "config", "script_url")),
        key = shell_quote(uci:get(name, "config", "script_key")) or get_key(),
    }
    uci:unload(name)
    return config
end

-- 执行命令
function exec_run()
    luci.http.header("application/json; charset=utf-8")
    -- 读取原始 POST 数据
    local request_body = luci.http.content()
    if not request_body then
        luci.http.write('{"msg":"空请求体"}')
        return
    end    
    -- 解析 JSON
    local ok, data = pcall(luci.jsonc.parse, request_body)
    if not ok or type(data) ~= "table" then
        luci.http.write(string.format('{"msg":"%s"}', data))
        return
    end
    -- 提取字段
    --local exec = data.cmd
    -- local port = data.port
    -- local token = data.token
    local example = data.example
   
    -- 参数验证
    --if not port or tonumber(port) == nil then
        --luci.http.write('{"msg":"端口无效"}')
        --return
    --end
    -- 验证 token
    --if not token then
        --luci.http.write('{"msg":"token 无效"}')
        --return
    --end
    
    -- 验证 Example
    if not example then
        luci.http.write('{"msg":"example 无效"}')
        return
    end
    
    -- 获取配置
    local cfg = get_config()
    local exec = string.format("wget -qO- '%s' | bash -s '%s'", cfg.url,cfg.key)
    -- local exec = "ping 127.0.0.1 -c 5"
    -- 后台执行
    local safe_exec = string.format("/usr/sbin/sseconsole -n %s run \"%s\" &", example, exec)
    --os.execute(safe_exec)
    luci.sys.exec(safe_exec)
    luci.http.write(string.format('{"msg":"%s"}', exec))
end

function exec_stop()
     luci.http.header( "application/json; charset=utf-8")
    -- 读取原始 POST 数据
    local request_body = luci.http.content()
    if not request_body then
        luci.http.write('{"msg":"空请求体"}')
        return
    end    
    -- 解析 JSON
    local ok, data = pcall(luci.jsonc.parse, request_body)
    if not ok or type(data) ~= "table" then
        luci.http.write(string.format('{"msg":"%s"}', data))
        return
    end
    
    -- 提取字段
    local example = data.example
    
    -- 验证 Example
    if not example then
        luci.http.write('{"msg":"example 无效"}')
        return
    end
    
    local cmd = string.format("/usr/sbin/sseconsole -n %s stop", example)
    luci.sys.exec(cmd)
    luci.http.write('{"msg":"stop"}')
end