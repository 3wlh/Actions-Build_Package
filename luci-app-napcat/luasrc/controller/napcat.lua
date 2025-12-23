module("luci.controller.napcat", package.seeall)

function index()
    -- 导入翻译模块（兼容新版 ucode）
    local i18n = require "luci.i18n"
    local _ = i18n.translate

    -- 注册到「服务」菜单下（核心变更）
    entry({"admin", "services", "napcat"}, firstchild(), _("NapCat QQ Bot"), 60).dependent = true

    -- 配置页面
    entry({"admin", "services", "napcat", "config"}, cbi("napcat"), _("配置"), 10).leaf = true

    -- 状态页面
    entry({"admin", "services", "napcat", "status"}, call("action_status"), _("状态"), 20).leaf = true

    -- 操作接口（启动/停止/重启）
    entry({"admin", "services", "napcat", "start"}, call("action_start")).leaf = true
    entry({"admin", "services", "napcat", "stop"}, call("action_stop")).leaf = true
    entry({"admin", "services", "napcat", "restart"}, call("action_restart")).leaf = true

    -- 获取容器日志接口
    entry({"admin", "services", "napcat", "logs"}, call("action_logs")).leaf = true

    -- 获取容器状态接口
    entry({"admin", "services", "napcat", "status_check"}, call("action_status_check")).leaf = true

    -- 获取快捷访问 URL 接口
    entry({"admin", "services", "napcat", "get_url"}, call("action_get_url")).leaf = true
end

-- 状态页面渲染
function action_status()
    luci.template.render("napcat/status")
end

-- 启动容器
function action_start()
    local result = {code = 0, msg = "启动成功"}
    local ret = os.execute("/etc/init.d/napcat start >/dev/null 2>&1")
    if ret ~= 0 then
        result.code = 1
        result.msg = "启动失败"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- 停止容器
function action_stop()
    local result = {code = 0, msg = "停止成功"}
    local ret = os.execute("/etc/init.d/napcat stop >/dev/null 2>&1")
    if ret ~= 0 then
        result.code = 1
        result.msg = "停止失败"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- 重启容器
function action_restart()
    local result = {code = 0, msg = "重启成功"}
    local ret = os.execute("/etc/init.d/napcat restart >/dev/null 2>&1")
    if ret ~= 0 then
        result.code = 1
        result.msg = "重启失败"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- 获取容器日志
function action_logs()
    local logs = luci.sys.exec("docker logs --tail=100 napcat 2>/dev/null || echo '容器未运行或日志为空'")
    luci.http.prepare_content("text/plain")
    luci.http.write(logs)
end

-- 检查容器状态
function action_status_check()
    local status = "stopped"
    local running = luci.sys.exec("docker inspect -f '{{.State.Running}}' napcat 2>/dev/null")
    if running:find("true") then
        status = "running"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({status = status})
end

-- 获取快捷访问 URL
function action_get_url()
    local uci = require("luci.model.uci").cursor()
    local main_port = uci:get("napcat", "main", "main_port") or "3000"
    local ip = luci.sys.exec("uci get network.lan.ipaddr 2>/dev/null | cut -d '/' -f1"):gsub("\n", "")
    local url = "http://" .. ip .. ":" .. main_port
    luci.http.prepare_content("application/json")
    luci.http.write_json({url = url})
end