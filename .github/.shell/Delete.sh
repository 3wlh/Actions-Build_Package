#!/bin/bash
function Del(){
PACKAGES_PATH="${1}"
PACKAGES_NAME=(${2})
for PREFIX in "${PACKAGES_NAME[@]}"; do
	file=$(find ${PACKAGES_PATH} -type f -name "*${PREFIX}*.[ia]pk")
	for name in $file; do
		[[ -f ${name} ]] && sudo rm -f ${name} && [[ -f ${name} ]] || \
		echo -e "$(date '+%Y-%m-%d %H:%M:%S')\e[1;31m - 【$(basename ${name})】插件删除.\e[0m"
	done
done
}
App_list=$(find "${1}" -type f -name "*.[ia]pk" -exec basename {} \;| cut -d '_' -f1)
Del "${2}" "${App_list}"