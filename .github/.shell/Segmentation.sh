#!/bin/bash
PACKAGES_PATH="${1}"
PACKAGES_URL="${2}"
PACKAGES_NAME=(${3})
wget -qO- "${PACKAGES_URL}/Packages" | \
while IFS= read -r LINE; do
    for PREFIX in "${PACKAGES_NAME[@]}"; do
        if [[ "$LINE" == "Filename"*${PREFIX}* ]]; then
            FILE=$(echo "$LINE" | grep -Eo ${PREFIX}'.*')
            if [[ -z "$FILE" ]]; then
                # echo "No file found in line, skipping"
                continue
            fi
            Download_URL="${PACKAGES_URL}${FILE}"
            if [[ ! -f "${PACKAGES_PATH}/${FILE}" ]];then
                Download "${Download_URL}" "${PACKAGES_PATH}"
            else
                echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;31m - 【${FILE}】插件无更新.\e[0m"
            fi   
        fi
    done
done