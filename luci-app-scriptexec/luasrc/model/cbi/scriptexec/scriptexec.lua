local io = require("io")
local string = require("string")

-- 生成解密密钥（Key）的函数
local function generate_key()
    local mac = nil
    -- 获取eth0 MAC
    local ip_cmd = io.popen("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if ip_cmd then
        mac = ip_cmd:read("*a"):gsub("%s+", "")
        ip_cmd:close()
    end
    -- 备用路径
    if not mac or mac == "" then
        local mac_file = io.open("/sys/class/net/eth0/address", "r")
        if mac_file then
            mac = mac_file:read("*a"):gsub("%s+", "")
            mac_file:close()
        end
    end
    -- 生成解密Key
    local key = ""
    if mac and mac ~= "" then
        local md5_cmd = io.popen("echo -n '" .. mac .. "' | md5sum | awk '{print $1}' | cut -c9-24")
        if md5_cmd then
            key = md5_cmd:read("*a"):gsub("%s+", "")
            md5_cmd:close()
        end
    end
    -- 同时返回MAC和解密Key
    return mac, key  
end

-- 生成MAC和解密Key
local device_mac, decrypt_key = generate_key()

-- 全中文配置
local m = Map("scriptexec", "同步配置",
    "从远程服务器拉取SH配置脚本，使用设备Key解密后执行" .. 
    (device_mac ~= "" and "<br><b>MAC地址: </b> <span style='color:#3498db;'>" .. device_mac .. "</span>" or "") ..
    (decrypt_key ~= "" and "<br><b>密钥Key: </b> <span style='color:#e74c3c;'>" .. decrypt_key .. "</span>" or ""))


m.ignore_errors = true  

local s = m:section(TypedSection, "general", "通用设置")
s.anonymous = true
s.addremove = false

-- 远程加密脚本URL
local config_url = s:option(Value, "exec_url", "远程脚本URL")
config_url.datatype = "string"
config_url.default = "http://example.com/netconfig_script.sh"
config_url.description = "远程加密配置脚本的地址（需用设备Key解密）<br>"
config_url.rmempty = false

-- 解密密钥
local config_key = s:option(Value, "exec_key", "解密Key")
config_key.datatype = "string"
config_key.password = true  -- 密码框样式
config_key.default = decrypt_key  -- 默认填充解密Key
config_key.description = "用于解密远程加密脚本的密钥（自动填充基于eth0 MAC生成的密钥）<br>"
config_key.rmempty = true

return m