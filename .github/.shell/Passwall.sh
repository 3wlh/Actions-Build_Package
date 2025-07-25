#!/bin/bash
Data="$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest)"
Zip_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*passwall_packages_ipk_'${1}'.zip"' | cut -d '"' -f 4)"
[[ -z "$(Check "passwall" "${Zip_url}" "${3}/${1}-")" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - 【passwall】插件无更新" && exit
luci_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-'${2}'.*\.ipk"' | head -1 | cut -d '"' -f 4)"
i18n_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-'${2}'.*\.ipk"' | tail -1 | cut -d '"' -f 4)"
Download_url=(${Zip_url} ${luci_url} ${i18n_url})
echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 luci-app-passwall ..."
for url in "${Download_url[@]}"; do
echo "Downloading ${url}"
if [[ "$(du -b "$(pwd)/packages/diy_packages/$(basename ${url})" 2>/dev/null | awk '{print $1}')" -ge "10000" ]]; then
	echo "######################################################################## 100.0%"
else	
	find $(pwd)/packages/diy_packages/ -type f -name "$(echo "$(basename ${url})")" -exec rm -f {} \;
	curl -# -L --fail "${url}" -o "$(pwd)/packages/diy_packages/$(basename ${url})"
fi
done
find $(pwd)/packages/diy_packages/ -type f -name "$(echo "$(basename ${Zip_url})")" -exec unzip -oq {} -d "$(pwd)/packages/diy_packages/" \;