local name = "scriptrun"
module("luci.model.cbi."..name..".api.download", package.seeall)
local fs  = require "nixio.fs"
local sys = require "luci.sys"

local install_dir = "/usr/sbin"
local lock_path   = "/tmp/"..name.."-dl.lock"

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

-- 计算设备架构信息, 拼装下载URL
-- bin_file:     二进制名 (如 *-script)
-- download_url: release 目录URL (不含文件名)
function arch_info(bin_file, download_url)
	local arch = sys.exec("uname -m 2>/dev/null") or ""
	arch = arch:gsub("%s+", "")
	local arch_map = { aarch64 = "arm64", x86_64 = "amd64" }
	local pkg_arch = arch_map[arch] or arch
	local bin_name = bin_file .. "-" .. pkg_arch
	return {
		arch = arch,
		pkg_arch = pkg_arch,
		bin_name = bin_name,
		bin_path = install_dir .. "/" .. bin_file,
		bin_url = download_url .. "/" .. bin_name,
	}
end

-- 二进制是否已安装且有效
-- bin_file: 二进制名
function installed(bin_file)
	return is_elf(install_dir .. "/" .. bin_file)
end

-- 下载二进制 (返回结果 table, 不碰 HTTP)
-- bin_path: 目标安装路径 (由调用方传入, 一般为 arch_info().bin_path)
-- bin_url:  完整下载URL (由调用方传入)
function download(bin_path, bin_url)
	-- 已存在且有效则跳过 (HTTP 超时后重试的场景)
	if is_elf(bin_path) then
		return { success = true }
	end
	-- 清理残留的无效文件 (空文件 / 错误页), 避免干扰后续下载
	os.remove(bin_path)

	-- 锁检查 (防止 reload 重复下载)
	if fs.access(lock_path) then
		local stat = fs.stat(lock_path)
		-- 锁未过期 (120 秒内), 视为有下载在进行
		if stat and (os.time() - stat.mtime < 120) then
			return { success = false, downloading = true }
		end
		-- 锁过期, 清理残留
		os.remove(lock_path)
	end

	-- 创建锁, 开始下载
	-- curl -f: HTTP 错误 (404 等) 返回非零, 不会把错误页当成二进制
	-- 末尾 || rm -f: 两种下载都失败时清理残留文件, 避免下次误判为已安装
	sys.call("touch " .. lock_path)
	local cmd = string.format(
		"wget -q -O '%s' '%s' 2>/dev/null && chmod 755 '%s' || (curl -fsL -o '%s' '%s' 2>/dev/null && chmod 755 '%s') || rm -f '%s'",
		bin_path, bin_url, bin_path, bin_path, bin_url, bin_path, bin_path)
	sys.call(cmd)
	os.remove(lock_path)

	-- ELF 校验: 失败但残留无效文件则清理
	local ok = is_elf(bin_path)
	if not ok and fs.access(bin_path) then
		os.remove(bin_path)
	end
	return { success = ok }
end
