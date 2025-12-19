#!/bin/bash
PACKAGES_URL="https://api.github.com/repos/3wlh/Actions-Build_Package/releases/tags/GitHub-Actions"
PACKAGES_ARCH="${1}"
PACKAGES_PATH="${2}"
PACKAGES_NAME=(${3})
function dl(){
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/${FILE}" && DIR="$(pwd)/${FILE}"
Data="$(curl -s ${PACKAGES_URL}_${FILE})"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${FILE}'.*'${PACKAGES_ARCH}'"' | cut -d '"' -f 4)"
[[ -z "$(Check "${FILE}" "${gz_url}" "${PACKAGES_PATH}/.")" ]] && echo -e "${Time}\e[1;32m - 【${FILE}】插件无更新.\e[0m" && return
echo "${Time} - 下载 ${FILE} ..."
curl -# -L --fail "${gz_url}" -o "${DIR}/$(basename ${gz_url})"
if [[ "$(du -b "${DIR}/$(basename ${gz_url})" 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
		echo -e "${Time}\e[1;31m - 【${DIR}/$(basename ${gz_url})】下载失败.\e[0m"
fi
find "${DIR}" -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "${DIR}" \;
Delete "${DIR}" "${PACKAGES_PATH}"
}

for FILE in "${PACKAGES_NAME[@]}"; do
    if [[ -n ${FILE} ]]; then
        dl         
     fi
done

