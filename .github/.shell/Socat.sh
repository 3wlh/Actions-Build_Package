#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" & mkdir -p "$(pwd)/socat" && DIR="$(pwd)/socat"
Data="$(curl -s https://api.github.com/repos/chenmozhijin/luci-app-socat/releases/latest)"
luci_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | head -1 | cut -d '"' -f 4)"
[[ -z "$(Check "socat" "${luci_url}" "${2}/.")" ]] && echo -e "${Time}\e[1;32m - 【socat】插件无更新.\e[0m" && exit
i18n_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | tail -1 | cut -d '"' -f 4)"
echo "${Time} - 下载 luci-app-socat ..."
Download_url=(${luci_url} ${i18n_url})
for url in "${Download_url[@]}"; do
echo "Downloading ${url}"
curl -# -L --fail "${url}" -o "${DIR}/$(basename ${url})"
if [[ "$(du -b "${DIR}/$(basename ${url})" 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
	echo -e "${Time}\e[1;31m - 【$(basename ${url})】下载失败.\e[0m"
fi
done
App_list=$(find "${DIR}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Delete "${2}" "${App_list}"