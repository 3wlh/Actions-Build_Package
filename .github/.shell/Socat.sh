#!/bin/bash
Data="$(curl -s https://api.github.com/repos/chenmozhijin/luci-app-socat/releases/latest)"
luci_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | head -1 | cut -d '"' -f 4)"
[[ -z "$(Check "socat" "${Zip_url}" "${3}/${1}-")" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - 【socat】插件无更新" && exit
i18n_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*luci-.*\.ipk"' | tail -1 | cut -d '"' -f 4)"
Download_url=(${luci_url} ${i18n_url})
echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 luci-app-socat ..."
for url in "${Download_url[@]}"; do
echo "Downloading ${url}"
if [[ "$(du -b "$(pwd)/packages/diy_packages/$(basename ${url})" 2>/dev/null | awk '{print $1}')" -ge "512" ]]; then
	echo "######################################################################## 100.0%"
else	
	find $(pwd)/packages/diy_packages/ -type f -name "$(echo "$(basename ${url})")" -exec rm -f {} \;
	curl -# -L --fail "${url}" -o "$(pwd)/packages/diy_packages/$(basename ${url})"
fi
done