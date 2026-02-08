module("luci.controller.scriptexec", package.seeall)

-- 拆分PID文件，区分普通执行和流式执行
local EXEC_PATH = "/tmp/scriptexec"
local EXEC_PID = "/tmp/scriptexec/exec.pid"
local EXEC_LOG = "/tmp/scriptexec/exec.log"

function index()
    entry({"admin", "system", "scriptexec"}, firstchild(), _("在线配置"), 90).dependent = true
    entry({"admin", "system", "scriptexec", "settings"}, cbi("scriptexec/scriptexec"), _("Settings"), 10).leaf = true
    entry({"admin", "system", "scriptexec", "execute"}, template("scriptexec/exec"), _("执行命令"), 20).leaf = true
    entry({"admin", "system", "scriptexec", "run"}, call("exec_run"), nil).leaf = true
    entry({"admin", "system", "scriptexec", "stop"}, call("exec_stop"), nil).leaf = true
    entry({"admin", "system", "scriptexec", "log"}, call("exec_log"), nil).leaf = true
    entry({"admin", "system", "scriptexec", "status"}, call("exec_status"), nil).leaf = true
end

-- 检查文件是否存在
local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
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

-- 读取runscript中的配置
local function get_variable()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = uci:get("runscript", "@general[0]", "script_url") or "",
        key = uci:get("runscript", "@general[0]", "script_key") or get_key()
    }
    uci:unload("runscript")
    return config
end

-- 新增：判断命令是否还在运行
function exec_status()
    luci.http.header("Content-Type", "application/json; charset=utf-8")
    local is_running = false
    if file_exists(EXEC_PID) then
        local pid = luci.sys.exec("cat " .. EXEC_PID):gsub("%s+", "") -- 去除空格/换行
        if pid and pid ~= "" then
            -- 检查PID对应的进程是否存活（核心：用kill -0检测进程）
            local ret = os.execute("kill -0 " .. pid .. " 2>/dev/null")
            is_running = (ret == 0)
        end
    end
    -- 返回JSON：{ "running": true/false }
    luci.http.write('{"running": ' .. (is_running and "true" or "false") .. '}')
end

-- 停止命令
function exec_stop()
    if file_exists(EXEC_PID) then
        local pid = luci.sys.exec("cat " .. EXEC_PID):gsub("%s+", "")
        if pid and pid ~= "" then
            os.execute("kill -9 " .. pid .. " 2>/dev/null")
        end
        os.remove(EXEC_PID)
    end
    os.execute("echo '' > " .. EXEC_LOG)
    luci.http.write("命令已停止")
end

-- 获取日志
function exec_log()
    luci.http.header("Content-Type", "text/plain; charset=utf-8")
    if file_exists(EXEC_LOG) then
        luci.http.write(luci.sys.exec("cat " .. EXEC_LOG))
    else
        luci.http.write("")
    end
end

-- 执行命令
function exec_run()
    --local exec = luci.http.formvalue("cmd")
    --if not exec or exec == "" then 
        --luci.http.write("请输入命令") 
        --return 
    --end
    os.execute("mkdir -p" .. EXEC_PATH)
    -- 停止已有命令
    exec_stop()
    local cfg = get_variable()
    local url = cfg.url:gsub("'", "'\\''") -- 转义单引号防注入
    local key = cfg.key:gsub("'", "'\\''") -- 转义单引号防注入
    
    local exec = string.format("wget -qO- '%s' | bash -s '%s'", url,key)
    -- 后台执行
    local safe_exec = exec:gsub("'", "'\\''") -- 转义单引号
    os.execute(string.format("bash -c '%s' >'%s' 2>&1 & echo $! >'%s'", safe_exec, EXEC_LOG, EXEC_PID))
    luci.http.write("命令已启动：" .. exec)
end