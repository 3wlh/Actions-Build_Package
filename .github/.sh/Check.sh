#!/bin/bash
test -f "${3}releases.txt" || touch "${3}releases.txt"
function modify(){
cat "${3}releases.txt" | \
while IFS= read -r LINE; do
    [[ -z "$(echo "${LINE}" | grep -Eo "^Package:${1}.*")" ]] && continue
    url=$(echo "${LINE}" | cut -d " " -f 2)
    if [[ "${2}" != "${url}" ]]; then
        echo "update"
        sed -i "s|${url}|${2}|" "${3}releases.txt"
        break
    fi
done   
}
Releases=$(cat "${3}releases.txt" 2>/dev/null)
if [[ "${Releases}" =~ "Package:${1}" ]]; then
    modify "Package:${1}" "${2}"
else
	echo "update" && echo "Package:${1} ${2}" >>"${3}releases.txt"
fi