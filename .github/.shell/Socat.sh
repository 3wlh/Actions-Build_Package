#!/bin/bash
mkdir -p "$(pwd)/socat" && DIR="$(pwd)/socat"
Data="$(curl -s https://api.github.com/repos/chenmozhijin/luci-app-socat/releases/latest)"
luci_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | head -1 | cut -d '"' -f 4)"
[[ -z "$(Check "socat" "${luci_url}" "${2}/${1}-")" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - 【socat】插件无更新" && exit
i18n_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | tail -1 | cut -d '"' -f 4)"
Download_url=(${luci_url} ${i18n_url})
echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 luci-app-socat ..."
for url in "${Download_url[@]}"; do
echo "Downloading ${url}"
if [[ "$(du -b "${DIR}/$(basename ${url})" 2>/dev/null | awk '{print $1}')" -ge "512" ]]; then
	echo "######################################################################## 100.0%"
else	
	curl -# -L --fail "${url}" -o "${DIR}/$(basename ${url})"
fi
done
App_list=$(find "${DIR}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Delete "${2}" "${App_list}"