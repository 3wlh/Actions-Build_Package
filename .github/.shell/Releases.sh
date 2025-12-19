#!/bin/bash
PACKAGES_URL="https://api.github.com/repos/3wlh/Actions-Build_Package/releases/tags/GitHub-Actions"
PACKAGES_ARCH="${1}"
PACKAGES_PATH="${2}"
PACKAGES_NAME=(${3})
while IFS= read -r LINE; do
    for PREFIX in "${PACKAGES_NAME[@]}"; do
        if [[ "$LINE" == "Filename"*${PREFIX}* ]]; then
            FILE=$(echo "$LINE" | grep -Eo ${PREFIX}'.*')
            if [[ -z "$FILE" ]]; then
                # echo "No file found in line, skipping"
                continue
            fi
            dl "${FILE}"
        fi
    done
done

function dl(){
Time="$(date '+%Y-%m-%d %H:%M:%S')" && mkdir -p "$(pwd)/${1}" && DIR="$(pwd)/${1}"
Data="$(curl -s ${PACKAGES_URL}_${1})"
gz_url="$(echo "${Data}" | grep -Eo '"browser_download_url":\s*".*'${1}'.*'${PACKAGES_ARCH}'"' | cut -d '"' -f 4)"
[[ -z "$(Check "${1}" "${gz_url}" "${PACKAGES_PATH}/.")" ]] && echo -e "${Time}\e[1;32m - 【${FILE}】插件无更新.\e[0m" && exit
echo "${Time} - 下载 ${1} ..."
curl -# -L --fail "${gz_url}" -o "${DIR}/$(basename ${gz_url})"
if [[ "$(du -b "${DIR}/$(basename ${ipk_url})" 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
		echo -e "${Time}\e[1;31m - 【${DIR}/$(basename ${gz_url})】下载失败.\e[0m"
fi
find "${DIR}" -type f -name "$(basename ${gz_url})" -exec tar -zxf {} -C "${DIR}" \;
Delete "${DIR}" "${PACKAGES_PATH}"
}