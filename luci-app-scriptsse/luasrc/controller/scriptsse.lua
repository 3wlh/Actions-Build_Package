module("luci.controller.scriptsse", package.seeall)

function index()
    entry({"admin", "system", "scriptsse"}, firstchild(), _("在线配置"), 90).dependent = true
    entry({"admin", "system", "scriptsse", "settings"}, cbi("scriptsse/scriptsse"), _("Settings"), 10).leaf = true
    entry({"admin", "system", "scriptsse", "execute"}, call("exec_sse"), _("执行命令"), 20).leaf = true
    entry({"admin", "system", "scriptsse", "cfg"}, call("exec_cfg"), nil).leaf = true
    entry({"admin", "system", "scriptsse", "run"}, call("exec_run"), nil).leaf = true
    entry({"admin", "system", "scriptsse", "stop"}, call("exec_stop"), nil).leaf = true
end

function exec_status()
    -- 一行完成：检查PID存活并返回对应字符串
    return (luci.sys.call("pidof /usr/share/sse/sse >/dev/null") == 0) and "true" or "false"
end

function exec_sse()
    if exec_status() then
        os.execute("/usr/share/sse/sse >/dev/null &")
    end
    luci.template.render("scriptsse/status")
end


-- 生成解密密钥（Key）的函数
local function get_key()
    local mac = nil
    -- 获取eth0 MAC（优先ip命令）
    local ip_cmd = io.popen("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if ip_cmd then
        mac = ip_cmd:read("*a"):gsub("%s+", "")
        ip_cmd:close()
    end
    -- 备用路径（sysfs）
    if not mac or mac == "" then
        local mac_file = io.open("/sys/class/net/eth0/address", "r")
        if mac_file then
            mac = mac_file:read("*a"):gsub("%s+", "")
            mac_file:close()
        end
    end
    -- 生成解密Key（MAC为空时返回空）
    local key = ""
    if mac and mac ~= "" then
        -- 安全拼接命令，避免注入风险
        local md5_cmd = io.popen(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", mac:gsub("'", "'\\''")))
        if md5_cmd then
            key = md5_cmd:read("*a"):gsub("%s+", "")
            md5_cmd:close()
        end
    end
    return key  
end

local function read_file(file_path)
    local file = io.open(file_path, "r")
    local content = file and file:read("*a") or ""  -- 文件打开失败则内容为空
    if file then file:close() end  -- 确保关闭文件句柄
    -- 正则说明：^%s*（开头空白）(%S+)（第一段）%s+（分隔空格）(%S+)（第二段）
    local part1, part2 = content:match("^%s*(%S+)%s+(%S+)")
    return part1 or "", part2 or ""
end


local function get_variable()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = uci:get("scriptsse", "@general[0]", "script_url") or "",
        key = uci:get("scriptsse", "@general[0]", "script_key") or get_key(),
    }
    uci:unload("scriptsse")
    return config
end


function exec_cfg()
    luci.http.header("Content-Type", "application/json; charset=utf-8")
    local port,token = read_file("/tmp/sse/sse.cfg")
    local response = string.format('{"port": "%s", "token": "%s"}',port,token)
    luci.http.write(response) 
end


-- 执行命令
function exec_run()
    luci.http.header("Content-Type", "application/json; charset=utf-8")
    --local exec = luci.http.formvalue("cmd")
    --if not exec or exec == "" then 
      --  luci.http.write("请输入命令") 
        --return 
    --end
    local port,token = read_file("/tmp/sse/sse.cfg")
    local cfg = get_variable()
    local url = cfg.url:gsub("'", "'\\''") -- 转义单引号防注入
    local key = cfg.key:gsub("'", "'\\''") -- 转义单引号防注入
    local exec = string.format("wget -qO- '%s' | bash -s '%s'", url,key)
    --local exec = string.format("ping 127.1 -c 20")
    -- 后台执行
    local safe_exec = string.format(
        "wget -qO- --post-data='%s' http://localhost:%s/exec >/dev/null",
        exec,
        port)
    os.execute(safe_exec)
    luci.http.write(string.format('{"msg":"%s"}', safe_exec))
end

function exec_stop()
     luci.http.header("Content-Type", "application/json; charset=utf-8")
    local port,token= read_file("/tmp/sse/sse.cfg")
    local cmd = string.format(
        "wget -qO- --post-data='exec' http://localhost:%s/exec >/dev/null",
        port
    )
    os.execute(cmd)
    luci.http.write('{"msg":"停止命令已下发"}')
end