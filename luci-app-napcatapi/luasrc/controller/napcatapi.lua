module("luci.controller.napcatapi", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/napcatapi") then
		return
	end
	entry({"admin", "services", "napcatapi"}, cbi("napcatapi/napcatapi"), _("NapCat Api"), 20).dependent = true
	entry({"admin", "services","napcatapi_status"}, call("Run_status"))
end

function Run_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("napcatapi", "config", "port"))
	local token = uci:get("napcatapi", "config", "token")
	local status = {
		running = (sys.call("pidof napcatapi >/dev/null") == 0),
		port = (port or 566),
		token = (token or 123)
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end