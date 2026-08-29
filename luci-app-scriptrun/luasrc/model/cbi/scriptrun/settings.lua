local name = debug.getinfo(1, "S").source:match("/([^/]+)/[^/]+$")
local uci = require "luci.model.uci".cursor()

-- 生成解密密钥（Key）的函数
-- 生成解密密钥（Key）的函数
local function generate_key()
    -- 获取eth0 MAC（优先ip命令）
    local cmd="ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'"
    local mac = luci.sys.exec(cmd):gsub("%s+", "")
    -- 备用方法
    if not mac or mac == "" then
        mac = luci.sys.exec("cat /sys/class/net/eth0/address 2>/dev/null"):gsub("%s+", "")
    end
    -- local mac = luci.sys.exec("ethtool -P eth0 | grep -o '[0-9a-f:]\{17\}' 2>/dev/null")
    local key = ""
    if mac and mac ~= "" then
        key = luci.sys.exec(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", mac)):gsub("%s+", "")
    end
    return mac, key
end

-- 生成MAC和解密Key
local device_mac, decrypt_key = generate_key()

-- 初始化配置（确保模板有数据可用）
local function init_config()
    if not uci:get(name, "config") then
        uci:set(name, "config", "main")
        uci:reorder(name, "config", 0)
    end
    -- 基础配置默认值
    uci:set(name, "config", "script_url", uci:get(name, "config", "script_url") or "")
    uci:set(name, "config", "script_key", uci:get(name, "config", "script_key") or decrypt_key)
    return
end

init_config()


-- 全中文配置
local m, s, o
m = Map(name, "配置设置",
    "从远程服务器拉取SH配置脚本，使用设备Key解密后执行" .. 
    (device_mac ~= "" and "<br><b>MAC地址: </b> <span style='color:#3498db;'>" .. device_mac .. "</span>" or "") ..
    (decrypt_key ~= "" and "<br><b>密钥Key: </b> <span style='color:#e74c3c;'>" .. decrypt_key .. "</span>" or ""))


m.ignore_errors = true  

s = m:section(TypedSection, "main", "通用设置")
s.anonymous = true
s.addremove = false

-- 远程加密脚本URL
o = s:option(Value, "script_url", "远程脚本URL")
o.placeholder = "http://example.com/script.sh"
o.datatype = "string"
o.description = "远程加密配置脚本的地址（需用设备Key解密）<br>"
o.rmempty = true

-- 解密密钥
o = s:option(Value, "script_key", "解密Key")
o.datatype = "string"
o.password = true  -- 密码框样式
o.default = decrypt_key  -- 默认填充解密Key
o.description = "用于解密远程加密脚本的密钥（自动填充基于eth0 MAC生成的密钥）<br>"
o.rmempty = true

return m