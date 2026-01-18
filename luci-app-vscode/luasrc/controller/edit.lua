module("luci.controller.edit", package.seeall)

local interface="edit1"
-- 定义要编辑的目标文件
local TARGET_FILE = "/root/vscode_config.txt"

function index()
    -- 注册到「服务」菜单
    entry({"admin", "services", "edit"}, firstchild(), _("VSCode"), 90).dependent = true
    -- 页面路由
    entry({"admin", "services", "edit", interface}, template("edit/edit1"), _("Edit"), 10).leaf = true
    -- 注册文件读写的 RPC 接口
    entry({"admin", "services", "edit", interface.."_read"}, call("Read_File"), nil).leaf = true
    entry({"admin", "services", "edit", interface.."_save"}, call("Save_File"), nil).leaf = true
end

-- 读取单个文件内容
function Read_File()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    -- 安全检查：文件是否存在
    if not fs.access(TARGET_FILE, "r") then
        http.write_json({ code = 1, msg = "File not found" })
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
    local content = http.formvalue("content")
    -- 安全检查：内容非空 + 文件可写
    if not content or not fs.access(TARGET_FILE, "w") then
        http.write_json({ code = 1, msg = "Invalid content or file not writable" })
        return
    end
    local res = fs.writefile(TARGET_FILE, content)

    if res then
        http.write_json({ code = 0, msg = "Save success" })
    else
        http.write_json({ code = 1, msg = "Failed to save file" })
    end
end