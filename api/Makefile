#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2024 xiaobao@linkease.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH:=$(ARCH)

PKG_NAME:=api
PKG_VERSION:=1.0
PKG_RELEASE:=6
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
PKG_SOURCE:=$(PKG_NAME).tar.gz
PKG_SOURCE_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/
PKG_HASH:=77384576aa59dbd90b35c41c3e22f2c79e8f03844367474fe293f6a0b4f492db

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=openwrt api
	DEPENDS:=@(x86_64||aarch64) +bash
	URL:=https://github.com/3wlh/
endef

define Package/$(PKG_NAME)/description
  openwrt api.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/api-$(PKG_ARCH) $(1)/usr/sbin/api
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
