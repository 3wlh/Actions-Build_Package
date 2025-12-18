#
# Copyright (C) 2017-2020
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=api
PKG_VERSION:=1.0
PKG_RELEASE:=6
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

PKG_RELEASE:=1

STRIP:=true

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=aarch64_generic
	PKG_HASH:=7aae96431ddf60965d467462e3e4691b0914aa9f8ae8efa06fcec045d9a3dd88
endif

ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
	PKG_HASH:=1e9b340eb3c122d2daa8cf97baac86febb3acfd7f046b2892c747e44b89e0552
endif

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=openwrt api
	DEPENDS:=@(aarch64||x86_64) +bash
	URL:=https://github.com/3wlh/
endef

define Package/$(PKG_NAME)/description
  openwrt api.
endef

define Download/$(PKG_NAME)
	URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/
	URL_FILE:=$(PKG_NAME)-$(PKG_ARCH)
	FILE:=$(PKG_NAME)-$(PKG_ARCH)
	HASH:=$(PKG_HASH)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(DL_DIR)/$(PKG_NAME)-$(PKG_ARCH) $(1)/usr/sbin/$(PKG_NAME)
	chmod +x $(1)/usr/sbin/$(PKG_NAME)
endef

$(eval $(call Download,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
