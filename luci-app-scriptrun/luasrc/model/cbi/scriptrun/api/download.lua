local name = "scriptrun"
module("luci.model.cbi."..name..".api.download", package.seeall)
local fs  = require "nixio.fs"
local sys = require "luci.sys"
local install_dir = "/usr/sbin"

-- 检查文件是否为有效 ELF 二进制 (前4字节 \x7fELF)
local function is_elf(path)
	local f = io.open(path, "rb")
	if not f then return false end
	local magic = f:read(4)
	f:close()
	-- Lua 5.1 不支持 \x7f 转义, 用十进制 \127 (0x7f)
	return magic == "\127ELF"
end

-- 本地文件大小 (字节), 不存在返回 0
local function file_size(path)
	local s = fs.stat(path)
	return s and tonumber(s.size) or 0
end

-- 远程文件总大小 (字节): curl HEAD 优先 (-L 跟随重定向), 失败回退 wget --spider
-- 取 Content-Length 末次 (重定向链中 200 的), 取不到返回 0
local function fetch_total(bin_url)
	-- ① curl HEAD: grep 末次 content-length (重定向链末尾 200 响应的)
	local out = sys.exec(string.format(
		"curl -fsIL --connect-timeout 5 --max-time 10 '%s' 2>/dev/null | grep -i 'content-length' | tail -1", bin_url)) or ""
	local n = tonumber(out:match(":%s*(%d+)"))
	if n and n > 0 then return n end
	-- ② wget --spider 回退 (curl 缺失或 HEAD 失败; -t/-T 短选项兼容 BusyBox)
	out = sys.exec(string.format(
		"wget --spider -S -t 1 -T 8 '%s' 2>&1 | grep -i 'content-length' | tail -1", bin_url)) or ""
	return tonumber(out:match(":%s*(%d+)")) or 0
end

-- 下载进程是否存活 (pgrep -f 匹配 目录和bin_url)
-- pgrep -f 读 /proc/PID/cmdline 全量命令行, 不受 ps 无终端截断影响 (URL 在末尾也能匹配)
-- 自匹配规避: pgrep 的 pattern 含 'wget'/'curl' 会命中执行 pgrep 的 sh 自身,
-- 用字符类 w[g]et / c[u]rl 使字面串不含 'wget'/'curl', 规避自匹配
local function dl_running(file,url)
	local cmd = string.format(
		"pgrep -f 'w[g]et.*%s.*%s' >/dev/null 2>&1 || pgrep -f 'c[u]rl.*%s.*%s' >/dev/null 2>&1",
		file,url,file,url)
	return sys.call(cmd) == 0
end

-- 计算设备架构信息, 拼装下载URL
function arch_info(bin_file, download_url)
	local arch = sys.exec("uname -m 2>/dev/null") or ""
	arch = arch:gsub("%s+", "")
	local arch_map = { aarch64 = "arm64", x86_64 = "amd64" }
	local pkg_arch = arch_map[arch] or arch
	local bin_url = string.format(download_url, pkg_arch)
	return {
		arch = arch,
		pkg_arch = pkg_arch,
		bin_name = bin_url:match("([^/]+)$"),
		bin_path = install_dir .. "/" .. bin_file,
		bin_url = bin_url,
	}
end

-- 二进制是否已安装且有效
function installed(bin_file)
	return is_elf(install_dir .. "/" .. bin_file)
end

-- 启动下载(若无进程) + 返回当前状态 (单接口, 前端轮询同一URL)
function download(bin_path, bin_url, client_total)
	-- 文件已存在且有效 → 成功
	-- 下载先写 .tmp 完成后才 mv 到 bin_path, 故 bin_path 存在即代表下载完整, 不会被 partial 文件误判
	if is_elf(bin_path) then
		return { success = true }
	end
	-- 文件不存在: 无下载进程才启动 (前端每 2s 轮询; 首次启动后后续轮询 dl_running=true 跳过, 防重复起 wget)
	local tmp = bin_path .. ".tmp"
	if not dl_running(tmp,bin_url) then
		os.remove(bin_path)
		-- 下到 .tmp, 成功后 mv 到 bin_path (原子替换), 避免 partial 文件前4字节 ELF magic 触发 is_elf 误判完成
		local cmd = string.format(
			"(wget -O '%s' '%s' && mv -f '%s' '%s' && chmod 755 '%s' || (curl -fsL --connect-timeout 30 -o '%s' '%s' && mv -f '%s' '%s' && chmod 755 '%s') || rm -f '%s' ) >/dev/null 2>&1 </dev/null &",
			tmp, bin_url, tmp, bin_path, bin_path, tmp, bin_url, tmp, bin_path, bin_path, tmp)
		sys.call(cmd)
	end
	-- 计算下载进度: tmp 已下载字节 / 远程总大小
	-- client_total 有效则直接用 (前端回传, 跳过 HEAD); 否则首次拉取
	local total = (client_total and client_total > 0) and client_total or fetch_total(bin_url)
	local cur = file_size(tmp)
	local pct = 0
	if total > 0 then
		pct = math.floor(cur * 100 / total)
		if pct > 99 then pct = 99 end  -- 未 mv 到 bin_path 前封顶 99, 与 success 区分
	end
	-- 下载中 (刚启动 或 上一次轮询已在跑); total 回传前端缓存
	return { success = false, downloading = true, percent = pct, total = total }
end
