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
	SECTION:=net
	CATEGORY:=Network
	TITLE:=openwrt api
	DEPENDS:=@(aarch64||x86_64) +bash
	URL:=https://github.com/3wlh/
endef

define Package/$(PKG_NAME)/description
  openwrt api.
endef

define Download/$(PKG_NAME)
<<<<<<< HEAD
	URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/
	URL_FILE:=$(PKG_NAME)_$(PKG_ARCH)
	FILE:=$(PKG_NAME)_$(PKG_ARCH)
=======
	URL:=https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-$(PKG_FULL_VERSION)
	URL_FILE:=$(PKG_ARCH)-qbittorrent-nox
	FILE:=qbittorrent-nox-$(PKG_ARCH)-$(PKG_FULL_VERSION)
>>>>>>> 1b1f3d374419bb24f3d122b7d5706bab3dbe2697
	HASH:=$(PKG_HASH)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
<<<<<<< HEAD
	$(INSTALL_BIN) $(DL_DIR)/$(PKG_NAME)_$(PKG_ARCH) $(1)/usr/sbin/$(PKG_NAME)
=======
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/api-$(PKG_ARCH) $(1)/usr/sbin/api
>>>>>>> 1b1f3d374419bb24f3d122b7d5706bab3dbe2697
endef

$(eval $(call Download,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
