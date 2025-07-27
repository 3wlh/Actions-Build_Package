#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" & mkdir -p "$(pwd)/openlist2" && DIR="$(pwd)/openlist2"
Data="$(curl -s https://api.github.com/repos/sbwml/luci-app-openlist2/releases/latest)"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*openwrt-24.10-'${1}'.tar.gz"' | cut -d '"' -f 4)"
[[ -z "$(Check "openlist2" "${gz_url}" "${2}/.")" ]] && echo -e "${Time}\e[1;32m - 【openlist2】插件无更新.\e[0m" && exit
echo "${Time} - 下载 luci-app-openlist2 ..."
echo "Downloading ${gz_url}"
curl -# -L --fail "${gz_url}" -o "${DIR}/$(basename ${gz_url})"
if [[ "$(du -b "${DIR}/$(basename ${gz_url})" 2>/dev/null | awk '{print $1}')" -le "20000" ]]; then
	echo -e "${Time}\e[1;31m - 【$(basename ${gz_url})】下载失败.\e[0m"
fi
find "${DIR}" -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "${DIR}" \;
App_list=$(find "${DIR}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Delete "${2}" "${App_list}"