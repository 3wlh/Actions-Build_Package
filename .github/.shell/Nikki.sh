#!/bin/bash
mkdir -p "$(pwd)/nikki" && DIR="$(pwd)/nikki"
Data="$(curl -s https://api.github.com/repos/nikkinikki-org/OpenWrt-nikki/releases/latest)"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${1}'-openwrt-24.10.tar.gz"' | cut -d '"' -f 4)"
[[ -z "$(Check "nikki" "${gz_url}" "${2}/${1}-")" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - 【nikki】插件无更新" && exit
echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 luci-app-nikki ..."
echo "Downloading ${gz_url}"
if [[ "$(du -b "${DIR}/$(basename ${gz_url})" 2>/dev/null | awk '{print $1}')" -ge "6000" ]]; then
	echo "######################################################################## 100.0%"
else	
	curl -# -L --fail "${gz_url}" -o "${DIR}/$(basename ${gz_url})"
    # #wget -qO "$(pwd)/packages/diy_packages/$(basename $Download_URL)" "${d_URL}" --show-progress
fi
find "${DIR}" -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "${DIR}" \;
App_list=$(find "${DIR}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Delete "${2}" "${App_list}"