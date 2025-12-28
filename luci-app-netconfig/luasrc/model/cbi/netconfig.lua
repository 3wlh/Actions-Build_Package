local io = require("io")
local string = require("string")

-- 生成解密密钥（Key）的函数（保留原有逻辑，无错误）
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
    return mac, key  -- 同时返回MAC和解密Key
end

-- 生成MAC和解密Key
local device_mac, decrypt_key = generate_key()

-- 全中文配置（无分栏 + 无校验）
local m = Map("netconfig", "网络配置同步",
    "从远程服务器拉取加密的SH配置脚本，使用设备Key解密后执行（执行前自动备份本地配置）" .. 
    (device_mac ~= "" and "<br><b>eth0 MAC地址:</b> <span style='color:#3498db;'>" .. device_mac .. "</span>" or "") ..
    (decrypt_key ~= "" and "<br><b>脚本解密密钥(Key):</b> <span style='color:#e74c3c;'>" .. decrypt_key .. "</span>" or ""))

-- 移除无意义的配置（无配置文件时忽略错误无效）
m.ignore_errors = true  

-- ========== 修复1：节名称改为通用的 "general"（易记忆，且符合UCI规范） ==========
-- 若坚持用 "config" 节，需确保配置文件中有对应节，建议改用 "general"
local s = m:section(TypedSection, "general", "通用设置")
s.anonymous = true
s.addremove = false

-- ========== 修复2：配置项名称改为全小写（UCI 规范，大小写敏感） ==========
-- 1. 远程加密脚本URL（关闭所有校验）
local config_url = s:option(Value, "config_url", "远程加密脚本URL")  -- 小写 config_url
config_url.datatype = "string"
config_url.default = "http://example.com/netconfig_script.enc"
config_url.description = "远程加密配置脚本的地址（需用设备Key解密）<br>"
config_url.rmempty = false

-- 2. 解密密钥（关闭密码校验）
local config_key = s:option(Value, "config_key", "解密密钥(Decrypt Key)")  -- 小写 config_key
config_key.datatype = "string"
config_key.password = true  -- 保留密码框样式（仅隐藏输入，不校验）
config_key.default = decrypt_key  -- 默认填充解密Key
config_key.description = "用于解密远程加密脚本的密钥（自动填充基于eth0 MAC生成的密钥）<br>"
config_key.rmempty = true

return m