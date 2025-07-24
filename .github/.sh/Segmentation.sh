#!/bin/bash
PACKAGES_URL="${1}"
PACKAGES_NAME=(${2})
wget -qO- "${PACKAGES_URL}" | \
while IFS= read -r LINE; do
    for PREFIX in "${PACKAGES_NAME[@]}"; do
        if [[ "$LINE" == *"$PREFIX"* ]]; then
            FILE=$(echo "$LINE" | grep -Eo 'href="[^"]*' | sed 's/href="//')
            if [[ -z "$FILE" ]]; then
                # echo "No file found in line, skipping"
                continue
            fi
            Download_URL="${PACKAGES_URL}${FILE}"
            Download "${Download_URL}"
        fi
    done
done