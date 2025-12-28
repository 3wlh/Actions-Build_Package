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

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))