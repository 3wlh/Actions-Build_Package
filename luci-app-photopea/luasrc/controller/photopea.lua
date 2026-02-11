module("luci.controller.photopea", package.seeall)

function index()
	entry({"admin", "services", "photopea"}, firstchild(), _("Photopea"), 90).dependent = true
	entry({"admin", "services","photopea_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", "photopea", "settings"}, cbi("photopea/settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", "photopea", "edit"}, template("photopea/edit"), _("Edit"), 20).leaf = true
	entry({"admin", "services", "photopea", "file"}, template("photopea/files"), _("Files"), 30).leaf = true
	entry({"admin", "services", "photopea", "logs"}, template("photopea/logs"), _("Logs"), 40).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("photopea", "config", "port"))
	local token = uci:get("photopea", "config", "token")
	local file_bin = "photopea"
	local find_cmd = "find /usr/sbin/ -maxdepth 1 -name photopea* -exec basename {} \\; | head -1"
    local fp = io.popen(find_cmd, "r")
    if fp then
        file_bin = fp:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
        fp:close()
    end
	local status = {
		running = (luci.sys.call("pidof "..file_bin.." >/dev/null") == 0),
		port = (port or 8887),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end