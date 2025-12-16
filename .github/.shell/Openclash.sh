#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/openclash" && DIR="$(pwd)/openclash"
Data="$(curl -s https://api.github.com/repos/3wlh/Actions-Build_Package/releases/tags/GitHub-Actions_luci-app-openclash-ninja)"
ipk_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-app-openclash-ninja.*"' | cut -d '"' -f 4)"
[[ -z "$(Check "openclash" "${ipk_url}" "${2}/.")" ]] && echo -e "${Time}\e[1;32m - 【openclash】插件无更新.\e[0m" && exit
echo "${Time} - 下载 luci-app-openclash-ninja ..."
curl -# -L --fail "${ipk_url}" -o "${DIR}/$(basename ${ipk_url})"
if [[ "$(du -b "${DIR}/$(basename ${ipk_url})" 2>/dev/null | awk '{print $1}')" -le "20000" ]]; then
	echo -e "${Time}\e[1;31m - 【${DIR}/$(basename ${ipk_url})】下载失败.\e[0m"
fi
Delete "${DIR}" "${2}"