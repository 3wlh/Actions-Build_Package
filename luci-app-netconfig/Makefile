include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netconfig
PKG_VERSION:=1.0
PKG_RELEASE:=$(shell date +%Y%m%d)
LUCI_LANG:=zh-cn
KG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

LUCI_TITLE:=LuCI Demo netconfig          # 应用名称
LUCI_PKGARCH:=all                          # 架构无关
LUCI_DEPENDS:=+luci-base			     # 依赖
LUCI_DESCRIPTION:=A demo for LuCI app dev  # 描述

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./root/usr/bin/netconfig.sh $(1)/usr/sbin
	chmod +x $(1)/usr/sbin/netconfig.sh
endef

include $(TOPDIR)/feeds/luci/luci.mk