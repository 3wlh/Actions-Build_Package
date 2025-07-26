#!/bin/bash
# find "$(pwd)/dl" -type f
cat "$(pwd)/repositories.conf" | \
while IFS= read -r LINE; do
    [[ -z "$(echo "${LINE}" | grep -Eo "^src/gz")" ]] && continue
    name=$(echo "${LINE}" | cut -d " " -f 2)
    url=$(echo "${LINE}" | cut -d " " -f 3)
    [[ -z "${name}" || -z "${url}" ]] && continue
    # echo -e "检查${name}更新：" 
    echo "Downloading ${url}/Packages.gz"
    curl -# --fail "${url}/Packages.gz" -o "/tmp/Packages.gz"
    md5url=$(find "/tmp/" -type f -name "Packages.gz" 2>/dev/null -exec md5sum -b {} \; | awk '{print $1}')
    md5name=$(find "$(pwd)/dl" -type f -name "${name}" 2>/dev/null -exec md5sum -b {} \; | awk '{print $1}')
    echo "插件${name}:{\"md5url\": \"${md5url}\",\"md5name\": \"${md5name}\"}"
    if [[ "${md5url}" == "${md5name}" ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;32m -【${name}】无更新插件.\e[0m\n"
    else
        # 删除 GitHub 缓存
        rm -rf "$(pwd)/dl/*"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;31m -【${name}】有更新插件.\e[0m"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;31m - 删除所有缓存插件！\e[0m\n"
        echo "cache=delete" >> "$(pwd)/bin/.bashrc"
        break
    fi
done