# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-napcatapi
PKG_VERSION:=1.0.0
PKG_RELEASE:=$(shell date +%Y%m%d)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
LUCI_TITLE:=LuCI app for NapCatAPI
LUCI_DEPENDS:=+napcatapi-static

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
