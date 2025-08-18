
module("luci.controller.cifs2", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/cifs2") then
		return
	end
	
	entry({"admin", "services", "cifs2"}, cbi("cifs2-mount/cifs2"), _("Mount NetShare"), 70).dependent = true
end
