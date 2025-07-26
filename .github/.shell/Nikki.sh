#!/bin/bash
echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 luci-app-nikki ..."
Data="$(curl -s https://api.github.com/repos/nikkinikki-org/OpenWrt-nikki/releases/latest)"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${1}'-openwrt-24.10.tar.gz"' | cut -d '"' -f 4)"
[[ -z "$(Check "nikki" "${gz_url}" "${2}/${1}-")" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - 【nikki】插件未更新" && exit 0 >/dev/null
echo "Downloading ${gz_url}"
if [[ "$(du -b "$(pwd)/packages/diy_packages/$(basename ${gz_url})" 2>/dev/null | awk '{print $1}')" -ge "6000" ]]; then
	echo "######################################################################## 100.0%"
else	
	find $(pwd)/packages/diy_packages/ -type f -name "$(basename ${gz_url})" -exec rm -f {} \;
	curl -# -L --fail "${gz_url}" -o "$(pwd)/packages/diy_packages/$(basename ${gz_url})"
    # #wget -qO "$(pwd)/packages/diy_packages/$(basename $Download_URL)" "${d_URL}" --show-progress
fi
find $(pwd)/packages/diy_packages/ -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "$(pwd)/packages/diy_packages/" \;
# find $(pwd)/packages/diy_packages -type f -name "*.[ia]pk" -exec mv -f {} "$(pwd)/packages/diy_packages/" \;