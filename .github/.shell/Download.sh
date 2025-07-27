#!/bin/bash
[[ $(curl -o /dev/null -s --head -w "%{http_code}" "${1}") -ge 400 ]] && exit
echo "Downloading ${1}"
find ${2} -type f -name "*$(echo "$(basename ${1})" | cut -d "_" -f1)*" -exec rm -f {} \;
curl -# -L --fail "${1}" -o "$(pwd)/$(basename ${1})"
# wget -qO "$(pwd)/$(basename ${1})" "${1}" --show-progress
if [[ "$(du -b $(pwd)/$(basename ${1}) 2>/dev/null | awk '{print $1}')" -le "512" ]]; then
    echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;31m - 【$(basename ${url})】下载失败.\e[0m"
fi