Segmentation "${1}/packages/x86_64" \
"https://dl.openwrt.ai/releases/24.10/packages/x86_64/kiddin9/" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel taskd luci-lib-xterm luci-lib-taskd luci-app-store luci-app-socat"
Segmentation "${1}/packages/x86_64" \
"https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/x86_64/luci/" \
"luci-app-homeproxy luci-i18n-homeproxy-zh-cn luci-app-ramfree luci-i18n-ramfree-zh-cn luci-app-argon-config luci-i18n-argon-config-zh-cn luci-theme-argon"
Passwall "x86_64" "24.10" "${1}"
Openlist2 "x86_64" "${1}"
Nikki "x86_64" "${1}"
# Socat "x86_64" "${1}"