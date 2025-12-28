module("luci.controller.netconfig", package.seeall)

function index()
    entry({"admin", "network", "netconfig"}, 
        firstchild(), 
        _("NetConfig Sync"), 90).dependent = true

    entry({"admin", "network", "netconfig", "settings"}, 
        cbi("netconfig"), 
        _("Settings"), 10).leaf = true

    entry({"admin", "network", "netconfig", "status"}, 
        template("netconfig/status"),
        _("Status"), 20).leaf = true
    entry({"admin", "network", "netconfig", "pull_apply"}, 
        call("pull_apply"), 
        nil).leaf = true
end

function pull_apply()
    local cmd = "/usr/bin/netconfig.sh pull_apply 2>&1"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    luci.http.prepare_content("application/json")
    luci.http.write_json({output = result})
end