#!/bin/bash
cat "${3}/releases.txt" | \
while IFS= read -r LINE; do
    [[ -z "${1}" || -z "${2}" || -z "${LINE}" ]] && continue
    [[ -z "$(echo "${LINE}" | grep -Eo "${1}")" ]] && continue
    data=${LINE} 
done
[[ -z "${data}" ]] && echo ${2} && echo "${1} ${2}" >>${3}/releases.txt 
[[ -n "${data}" ]] && name=$(echo "${data}" | cut -d " " -f 1)
[[ -n "${data}" ]] && url=$(echo "${data}" | cut -d " " -f 2)
if [[ -n "${data}" && "${2}" != "${url}" ]]; then
    echo ${2}
    sed -i "s|${url}|${2}|" ${3}/releases.txt
fi
