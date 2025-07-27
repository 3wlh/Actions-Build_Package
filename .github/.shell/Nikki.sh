#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/nikki" && DIR="$(pwd)/nikki"
Data="$(curl -s https://api.github.com/repos/nikkinikki-org/OpenWrt-nikki/releases/latest)"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${1}'-openwrt-24.10.tar.gz"' | cut -d '"' -f 4)"
[[ -z "$(Check "nikki" "${gz_url}" "${2}/.")" ]] && echo -e "${Time}\e[1;32m - 【nikki】插件无更新.\e[0m" && exit
echo "${Time} - 下载 luci-app-nikki ..."
echo "Downloading ${gz_url}"
curl -# -L --fail "${gz_url}" -o "${DIR}/$(basename ${gz_url})"
if [[ "$(du -b "${DIR}/$(basename ${gz_url})" 2>/dev/null | awk '{print $1}')" -le "6000" ]]; then
	echo -e "${Time}\e[1;31m - 【$(basename ${url})】下载失败.\e[0m"
fi
find "${DIR}" -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "${DIR}" \;
Delete "${DIR}" "${2}"