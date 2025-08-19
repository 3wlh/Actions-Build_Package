
module("luci.controller.cifs", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/cifs") then
		return
	end
	
	entry({"admin", "services", "cifs"}, cbi("cifs-mount/cifs"), _("Mount NetShare"), 70).dependent = true
end
