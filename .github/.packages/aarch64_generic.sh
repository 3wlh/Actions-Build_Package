#!/bin/bash
Segmentation "${1}/packages/aarch64_generic" \
"https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9/" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel taskd luci-lib-xterm luci-lib-taskd luci-app-store luci-app-socat"
Segmentation "${1}/packages/aarch64_generic" \
"https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_generic/luci/" \
"luci-app-homeproxy luci-i18n-homeproxy-zh-cn luci-app-ramfree luci-i18n-ramfree-zh-cn luci-app-argon-config luci-i18n-argon-config-zh-cn luci-theme-argon"
Passwall "aarch64_generic" "24.10" "${1}"
Openlist2 "aarch64_generic" "${1}"
Nikki "aarch64_generic" "${1}"
# Socat "aarch64_generic" "${1}"