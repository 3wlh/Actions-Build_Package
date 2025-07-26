#!/bin/bash
Segmentation "https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9/" \
"${1}/packages/aarch64_generic" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel \
taskd luci-lib-xterm luci-lib-taskd luci-app-store"
Passwall "aarch64_generic" "24.10" "${1}"
Openlist2 "aarch64_generic" "${1}"
Nikki "aarch64_generic" "${1}"