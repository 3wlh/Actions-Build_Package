#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/openclash" && DIR="$(pwd)/openclash"
IPK_url="https://github.com/3wlh/Actions-Build_Package/releases/download/2025.12.15_001200/luci-app-openclash-ninja_0.47.028_all.ipk"
echo "${Time} - 下载 luci-app-openclash-ninja ..."
curl -# -L --fail "${IPK_url}" -o "${DIR}/$(basename ${IPK_url})"
if [[ "$(du -b "${DIR}/$(basename ${IPK_url})" 2>/dev/null | awk '{print $1}')" -le "20000" ]]; then
	echo -e "${Time}\e[1;31m - 【${DIR}/$(basename ${IPK_url})】下载失败.\e[0m"
fi
Delete "${DIR}" "${2}"