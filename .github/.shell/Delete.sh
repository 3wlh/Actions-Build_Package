#!/bin/bash
PACKAGES_PATH="${1}"
PACKAGES_NAME=(${2})
for PREFIX in "${PACKAGES_NAME[@]}"; do
	file=$(find ${PACKAGES_PATH} -type f -name "*${PREFIX}*.[ia]pk")
	[[ -f ${file} ]] && rm -f ${file} && \
	echo "$(date '+%Y-%m-%d %H:%M:%S') - 【$(basename ${file})】插件删除."
done
