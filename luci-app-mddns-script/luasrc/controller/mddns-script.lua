local name = "mddns-script"
module("luci.controller."..name, package.seeall)

function index()
	-- 菜单始终注册 (二进制检查在 action_index 实时执行, 避免菜单缓存导致下载后不刷新)
	entry({"admin", "services", name}, call("action_index"), _("MultiDDNS"), 90).dependent = true
	entry({"admin", "services",name.."_status"}, call("Run_status")).leaf = true
	entry({"admin", "services", name, "download_exec"}, call("action_download")).leaf = true
	-- 注册菜单 
	entry({"admin", "services", name, "settings"}, cbi(name.."/settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "parse"}, call("template", "parse"), _("Parse"), 20).leaf = true
	entry({"admin", "services", name, "logs"}, call("template", "logs"), _("Logs"), 30).leaf = true
end

function template(index)
	luci.template.render(name.."/"..index, {
		Name = name,
	})
end

function Run_status()
	luci.http.prepare_content("application/json")
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get(name, "config", "port"))
	local token = uci:get(name, "config", "token")
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
		port = (port or 5063),
		token = (token or "")
	}
	luci.http.write_json(status)
end

local download_url = "https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_mddns-script"

-- 检查文件是否为有效 ELF 二进制 (前4字节 \x7fELF)
-- 防止 404 HTML 错误页 / 空文件被误判为已安装的二进制
local function is_elf(path)
	local f = io.open(path, "rb")
	if not f then return false end
	local magic = f:read(4)
	f:close()
	-- Lua 5.1 不支持 \x7f 转义, 用十进制 \127 (0x7f)
	return magic == "\127ELF"
end

-- 主入口: 实时检查二进制, 存在则跳转设置页, 不存在则显示下载页面
function action_index()
	if is_elf("/usr/sbin/"..name) then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", name, "settings"))
	else
		-- 计算架构信息传入模板 (避免模板内重复执行 uname)
		local arch = luci.sys.exec("uname -m 2>/dev/null") or ""
		arch = arch:gsub("%s+", "")
		local arch_map = { aarch64 = "arm64", x86_64 = "amd64" }
		local pkg_arch = arch_map[arch] or arch
		local bin_name = "mddns-script-" .. pkg_arch
		luci.template.render(name.."/download", {
			Name = name,
			arch = arch,
			pkg_arch = pkg_arch,
			bin_name = bin_name,
			bin_dir = "/usr/sbin/"..name,
			bin_url = download_url .. "/" .. bin_name
		})
	end
end



-- 下载二进制到 /usr/sbin/ (从 GitHub release 拉取匹配架构的二进制)
-- 用锁文件防止 reload 导致重复下载
function action_download()
	local arch = luci.sys.exec("uname -m 2>/dev/null") or ""
	arch = arch:gsub("%s+", "")
	local arch_map = { aarch64 = "arm64", x86_64 = "amd64" }
	local pkg_arch = arch_map[arch] or arch
	local bin_url  = download_url .. "/mddns-script-" .. pkg_arch
	local bin_path = "/usr/sbin/" .. name
	local lock_path = "/tmp/mddns-dl.lock"

	-- 二进制已存在且有效则跳过 (处理 HTTP 超时后重试的场景)
	-- 用 ELF 魔数校验, 避免上次失败残留的 404 HTML 被误判为已安装
	if is_elf(bin_path) then
		luci.http.prepare_content("application/json")
		luci.http.write_json({ success = true })
		return
	end
	-- 清理残留的无效文件 (空文件 / 错误页), 避免干扰后续下载
	os.remove(bin_path)

	-- 检查锁 (防止 reload 重复下载)
	if nixio.fs.access(lock_path) then
		local stat = nixio.fs.stat(lock_path)
		-- 锁未过期 (120 秒内), 视为有下载在进行
		if stat and (os.time() - stat.mtime < 120) then
			luci.http.prepare_content("application/json")
			luci.http.write_json({ success = false, downloading = true })
			return
		end
		-- 锁过期, 清理残留
		os.remove(lock_path)
	end

	-- 创建锁, 开始下载
	luci.sys.call("touch " .. lock_path)
	-- curl -f: HTTP 错误 (404 等) 返回非零, 不会把错误页当成二进制
	-- 末尾 || rm -f: 两种下载都失败时清理残留文件, 避免下次误判为已安装
	local cmd = string.format(
		"wget -q -O '%s' '%s' 2>/dev/null && chmod 755 '%s' || (curl -fsL -o '%s' '%s' 2>/dev/null && chmod 755 '%s') || rm -f '%s'",
		bin_path, bin_url, bin_path, bin_path, bin_url, bin_path, bin_path)
	luci.sys.call(cmd)

	-- 删除锁
	os.remove(lock_path)

	-- 验证: 必须是有效 ELF 二进制 (防 404 HTML / 空文件)
	local ok = is_elf(bin_path)
	if not ok and nixio.fs.access(bin_path) then
		-- 下载失败但残留了无效文件, 清理掉
		os.remove(bin_path)
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		success = ok,
		arch = arch,
		pkg_arch = pkg_arch
	})
end
