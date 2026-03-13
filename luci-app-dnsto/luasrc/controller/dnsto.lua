module("luci.controller.dnsto", package.seeall)

function index()
	entry({"admin", "services", "dnsto"}, firstchild(), _("DNDTO"), 90).dependent = true
	entry({"admin", "services","dnsto_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", "dnsto", "settings"}, cbi("dnsto/napcatapi"), _("Settings"), 10).leaf = true
	entry({"admin", "services", "dnsto", "index"}, template("dnsto/index"), _("Index"), 20).leaf = true
	entry({"admin", "services", "dnsto", "logs"}, template("dnsto/logs"), _("Logs"), 30).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("dnsto", "config", "port"))
	local token = uci:get("dnsto", "config", "token")
	local file_bin = "dnsto"
	local find_cmd = "find /usr/sbin/ -maxdepth 1 -name dnsto* -exec basename {} \\; | head -1"
    local fp = io.popen(find_cmd, "r")
    if fp then
        file_bin = fp:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
        fp:close()
    end
	local status = {
		running = (luci.sys.call("pidof "..file_bin.." >/dev/null") == 0),
		port = (port or 5063),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end