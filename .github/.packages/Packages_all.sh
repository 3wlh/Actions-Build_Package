#!/bin/bash
ARCH="${1}"
PACKAGES_PATH="${2}/packages/${ARCH}"
mkdir -p "/tmp/packages/${ARCH}" && cd "/tmp/packages/${ARCH}"
Passwall "${ARCH}" "24.10" "${PACKAGES_PATH}"
Openlist2 "${ARCH}" "${PACKAGES_PATH}"
Nikki "${ARCH}" "${PACKAGES_PATH}"
# Socat "${ARCH}" "${PACKAGES_PATH}"
Segmentation "${PACKAGES_PATH}" "https://dl.openwrt.ai/releases/24.10/packages/${ARCH}/kiddin9" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel luci-app-socat"
Segmentation "${PACKAGES_PATH}" "https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/${ARCH}/luci" \
"luci-app-homeproxy luci-i18n-homeproxy-zh-cn luci-app-ramfree luci-i18n-ramfree-zh-cn 
luci-app-argon-config luci-i18n-argon-config-zh-cn luci-theme-argon"
Segmentation "${PACKAGES_PATH}" "https://istore.istoreos.com/repo/all/store" \
"taskd luci-lib-xterm luci-lib-taskd luci-app-store"
