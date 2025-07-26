#!/bin/bash
cat "${3}releases.txt" 2>/dev/null | \
while IFS= read -r LINE; do
    [[ -z "${LINE}" ]] && echo ${2} && echo "${1} ${2}" >>${3}releases.txt && break
    [[ -z "$(echo "${LINE}" | grep -Eo "${1}")" ]] && continue
    [[ -n "${LINE}" ]] && name=$(echo "${data}" | cut -d " " -f 1)
    [[ -n "${LINE}" ]] && url=$(echo "${data}" | cut -d " " -f 2)
    if [[ -n "${LINE}" && "${2}" != "${url}" ]]; then
        echo ${2}
        sed -i "s|${url}|${2}|" "${3}releases.txt"
        break
    fi
done

