#!/bin/bash
Time="$(date '+%Y-%m-%d %H:%M:%S')" & mkdir -p "$(pwd)/passwall" && DIR="$(pwd)/passwall"
Data="$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest)"
Zip_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*passwall_packages_ipk_'${1}'.zip"' | cut -d '"' -f 4)"
[[ -z "$(Check "passwall" "${Zip_url}" "${3}/.")" ]] &&  -e "${Time}\e[1;32m - 【passwall】插件无更新.\e[0m" && exit
luci_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-'${2}'.*\.ipk"' | head -1 | cut -d '"' -f 4)"
i18n_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-'${2}'.*\.ipk"' | tail -1 | cut -d '"' -f 4)"
echo "${Time} - 下载 luci-app-passwall ..."
Download_url=(${Zip_url} ${luci_url} ${i18n_url})
for url in "${Download_url[@]}"; do
echo "Downloading ${url}"
curl -# -L --fail "${url}" -o "${DIR}/$(basename ${url})"
if [[ "$(du -b "${DIR}/$(basename ${url})" 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
	echo -e "${Time}\e[1;31m - 【$(basename ${url})】下载失败.\e[0m"
fi
done
find "${DIR}" -type f -name "$(echo "$(basename ${Zip_url})")" -exec unzip -oq {} -d "${DIR}" \;
App_list=$(find "${DIR}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Delete "${3}" "${App_list}"