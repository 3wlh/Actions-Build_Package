module("luci.controller.vscode", package.seeall)

function index()
    -- 注册到「服务」菜单
    entry({"admin", "services", "vscode"}, firstchild(), _("VSCode"), 90).dependent = true
    entry({"admin", "services", "vscode", "settings"}, cbi("vscode/vscode"), _("VSCode设置"), 10).leaf = true
    -- 页面路由
    entry({"admin", "services", "vscode", "edit"}, template("vscode/edit"), _("VSCode配置"), 20).leaf = true
    -- 注册文件读写的 RPC 接口
    entry({"admin", "services", "vscode", "read"}, call("Read_File"), nil).leaf = true
    entry({"admin", "services", "vscode", "save"}, call("Save_File"), nil).leaf = true
end

-- 定义要编辑的目标文件
local TARGET_FILE = "/root/vscode_config.txt"

-- 读取单个文件内容
function Read_File()
    local fs = require "nixio.fs"
    local http = require "luci.http"

    -- 安全检查：文件是否存在
    if not fs.access(TARGET_FILE, "r") then
        http.write_json({ code = 1, msg = "File not found: " .. TARGET_FILE })
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
    local content = http.formvalue("content") or "456"
    -- 安全检查：内容非空 + 文件可写
    if not content or not fs.access(TARGET_FILE, "w") then
        http.write_json({ code = 1, msg = "Invalid content or file not writable" })
        return
    end
    -- 写入文件（先备份原文件，可选）
    -- fs.copy(TARGET_FILE, TARGET_FILE .. ".bak")
    local res = fs.writefile(TARGET_FILE, content)

    if res then
        http.write_json({ code = 0, msg = "Save success" })
    else
        http.write_json({ code = 1, msg = "Failed to save file" })
    end
end