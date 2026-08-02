#!/bin/bash
PACKAGES_URL="https://api.github.com/repos/3wlh/OpenWrt_Packages/releases/tags/GitHub-Actions_luci-app-mddns-script"
PACKAGES_NAME=("luci-app-mddns-script" "mddns-aliyun-script" "mddns-cloudflare-script" "mddns-dnshe-script" "mddns-dnspod-script" "mddns-spaceship-script")
PACKAGES_ARCH="${1}"
PACKAGES_PATH="${2}"
function dl(){
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/Mddns" && DIR="$(pwd)/Mddns"
IPK_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${FILE}'.*'${PACKAGES_ARCH}'.*"' | cut -d '"' -f 4)"
[[ -z "$(Check "${FILE}" "${IPK_url}" "${PACKAGES_PATH}")" ]] && echo -e "${Time} - \e[1;32m【${FILE}】插件无更新.\e[0m" && return
echo "${Time} - 下载 ${FILE} ..."
curl -# -L --fail "${IPK_url}" -o "${DIR}/$(basename ${IPK_url})"
if [[ "$(du -b "${DIR}/$(basename ${IPK_url})" 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
		echo -e "${Time} - \e[1;31m【${DIR}/$(basename ${IPK_url})】下载失败.\e[0m"
fi
Delete "${DIR}" "${PACKAGES_PATH}"
}

Data="$(curl -s ${PACKAGES_URL})"
for FILE in "${PACKAGES_NAME[@]}"; do
    if [[ -n ${FILE} ]]; then
        dl         
     fi
done