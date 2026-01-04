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
	entry({"admin", "services", "napcatapi", "log"}, template("napcatapi/log"), _("Log"), 40).leaf = true
end

function Run_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("napcatapi", "config", "port"))
	local token = uci:get("napcatapi", "config", "token")
	local status = {
		running = (sys.call("pidof napcatapi >/dev/null") == 0),
		port = (port or 566),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

