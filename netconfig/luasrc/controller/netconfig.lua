module("luci.controller.netconfig", package.seeall)

function index()
    entry({"admin", "system", "netconfig"}, 
        firstchild(), 
        _("在线配置"), 90).dependent = true

    entry({"admin", "system", "netconfig", "settings"}, 
        cbi("netconfig"), 
        _("Settings"), 10).leaf = true

    entry({"admin", "system", "netconfig", "status"}, 
        template("netconfig/status"),
        _("Status"), 20).leaf = true
    entry({"admin", "system", "netconfig", "pull_apply"}, 
        call("pull_apply"), 
        nil).leaf = true
end

function pull_apply()
    local cmd = "/usr/sbin/netconfig.sh pull_apply 2>&1"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    luci.http.prepare_content("application/json")
    luci.http.write_json({output = result})
end