module("luci.controller.napcatapi", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/napcatapi") then
		return
	end
	entry({"admin", "services", "napcatapi"}, firstchild(), _("NapCat Api"), 90).dependent = true
	entry({"admin", "services","napcatapi_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", "napcatapi", "settings"}, cbi("napcatapi/napcatapi"), _("Settings"), 10).leaf = true
	entry({"admin", "services", "napcatapi", "edit"}, template("napcatapi/edit"), _("Edit"), 20).leaf = true
	entry({"admin", "services", "napcatapi", "napcat"}, template("napcatapi/napcat"), _("NapCat"), 30).leaf = true
	entry({"admin", "services", "napcatapi", "logs"}, template("napcatapi/logs"), _("Logs"), 40).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("napcatapi", "config", "port"))
	local token = uci:get("napcatapi", "config", "token")
	local file_bin = "napcatapi"
	local find_cmd = "find /usr/sbin/ -maxdepth 1 -name napcatapi* -exec basename {} \\; | head -1"
    local fp = io.popen(find_cmd, "r")
    if fp then
        file_bin = fp:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
        fp:close()
    end
	local status = {
		running = (luci.sys.call("pidof "..file_bin.." >/dev/null") == 0),
		port = (port or 5663),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end