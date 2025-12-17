#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2024 xiaobao@linkease.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_api:=$(ARCH)

PKG_NAME:=api
PKG_VERSION:=1.0
PKG_RELEASE:=6
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
PKG_SOURCE:=$(PKG_NAME).tar.gz
PKG_SOURCE_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/
PKG_HASH:=skip

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
    CATEGORY:=Utilities
	TITLE:=openwrt api
	DEPENDS:=@(x86_64||aarch64) +bash +libstdcpp6
	URL:=https://github.com/3wlh/
endef

define Package/$(PKG_NAME)/description
  openwrt api.
endef

define Build/Configure
	$(call Build/Configure/Default)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/api.$(PKG_ARCH) $(1)/usr/sbin/api
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
