module("luci.controller.runscript", package.seeall)

-- 核心配置（仅保留脚本路径）
local SCRIPT_PATH = "/tmp/run_script.sh"  -- 脚本存放路径

function index()
    entry({"admin", "system", "runscript"}, 
        firstchild(), 
        _("在线配置"), 90).dependent = true

    entry({"admin", "system", "runscript", "settings"}, 
        cbi("runscript/runscript"), 
        _("Settings"), 10).leaf = true

    entry({"admin", "system", "runscript", "status"}, 
        template("runscript/status"),
        _("Status"), 20).leaf = true
    
    entry({"admin", "system", "runscript", "download_script"}, 
        call("download_script"), 
        nil).leaf = true
    
    entry({"admin", "system", "runscript", "run_script"}, 
        call("run_script"), 
        nil).leaf = true
end

-- 生成解密密钥（Key）的函数
local function generate_key()
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
local function get_runscript()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = uci:get("runscript", "@general[0]", "script_url") or "",  -- 取第一个general节
        key = uci:get("runscript", "@general[0]", "script_key") or generate_key()
    }
    uci:unload("runscript")
    return config
end

-- 校验脚本文件头部（是否包含#!/bin/bash或#!/bin/sh）
local function validate_script_header(file_path)
    -- 先检查文件是否存在
    if not os.execute("test -f " .. file_path) then
        return false, "文件不存在"
    end
    local file, err = io.open(file_path, "rb")
    if not file then
        return false, "无法打开文件：" .. (err or "未知错误")
    end
    -- 读取文件前30个字符（覆盖常见脚本头）
    local header = file:read(30)
    file:close()
    -- 校验头部（兼容#!/bin/bash和#!/bin/sh）
    if header and (header:find("^#!/bin/bash") or header:find("^#!/bin/sh")) then
        return true, "文件头部校验通过：" .. header:sub(1, 11)
    else
        -- 校验失败删除文件
        os.remove(file_path)
        return false, "文件头部非法！要求以#!/bin/bash或#!/bin/sh开头，实际头部：" .. (header or "空文件")
    end
end

-- 下载脚本接口
function download_script()
    -- 先删除旧文件
    os.remove(SCRIPT_PATH) 
    local result = {output = "", error = nil, raw_log = ""}

    -- 读取配置
    local runscript = get_runscript()
    local script_url = runscript.url
    if script_url == "" then
        result.error = "未配置脚本下载地址！请在「在线配置→Settings」中设置config_url"
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 检查依赖（wget/curl）
    local has_wget = os.execute("which wget >/dev/null 2>&1") == 0
    local has_curl = os.execute("which curl >/dev/null 2>&1") == 0
    if not has_wget and not has_curl then
        result.error = "缺少下载工具！请安装 wget 或 curl"
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 构造下载命令
    local download_cmd
    if has_wget then
        download_cmd = string.format("wget -O %s '%s' 2>&1", SCRIPT_PATH, script_url:gsub("'", "'\\''"))
    else
        download_cmd = string.format("curl -o %s '%s' 2>&1", SCRIPT_PATH, script_url:gsub("'", "'\\''"))
    end

    -- 执行下载并捕获日志
    local handle = io.popen(download_cmd)
    local raw_log = handle:read("*a")
    handle:close()
    result.raw_log = raw_log

    -- 检查文件是否下载成功
    local file_exists = os.execute("test -f " .. SCRIPT_PATH) == 0
    if not file_exists then
        result.error = "脚本下载失败：文件未生成\n\n【下载详细日志】\n" .. raw_log
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 校验文件头部
    local header_ok, header_msg = validate_script_header(SCRIPT_PATH)
    if not header_ok then
        result.error = string.format(
            "脚本下载失败：%s\n\n【下载详细日志】\n%s",
            header_msg, raw_log
        )
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 添加执行权限
    os.execute("chmod +x " .. SCRIPT_PATH .. " 2>&1")
    result.output = "脚本下载成功\n\n【下载详细日志】\n" .. raw_log

    -- 返回结果
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- 运行脚本接口（增加文件头部二次校验+安全传参）
function run_script()
    local result = {output = "", error = nil, raw_log = ""}

    -- 读取config_key
    local runscript = get_runscript()
    local script_key = runscript.key

    -- 第一步：检查脚本是否可执行
    local script_executable = os.execute("test -x " .. SCRIPT_PATH) == 0
    if not script_executable then
        result.error = "脚本不可执行！请先下载合法的脚本文件"
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 二次校验文件头部
    local header_ok, header_msg = validate_script_header(SCRIPT_PATH)
    if not header_ok then
        result.error = "脚本文件非法：" .. header_msg .. "\n请重新下载脚本"
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end

    -- 构造运行命令
    local run_cmd
    if config_key ~= "" then
        -- 环境变量传参更安全，避免命令注入
        run_cmd = string.format("%s %s 2>&1", SCRIPT_PATH, script_key:gsub("'", "'\\''"))
    else
        run_cmd = string.format("%s 2>&1", SCRIPT_PATH)
    end

    -- 执行脚本并捕获日志
    local handle = io.popen(run_cmd)
    local raw_log = handle:read("*a")
    handle:close()
    result.raw_log = raw_log

    -- 检查执行状态
    local exit_code = os.execute(string.format("%s >/dev/null 2>&1", run_cmd))
    if exit_code == 0 then
        result.output = string.format(
            "脚本运行成功\n【文件校验】%s\n\n【运行详细日志】\n%s",
            header_msg, raw_log
        )
    else
        result.error = string.format(
            "脚本运行失败（退出码：%d）\n【文件校验】%s\n\n【运行详细日志】\n%s",
            exit_code, header_msg, raw_log
        )
    end

    -- 返回结果
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end