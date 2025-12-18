#
# Copyright (C) 2017-2020
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=api
PKG_VERSION:=1.0
# PKG_RELEASE:=6
PKG_RELEASE:=20220422
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

PKG_RELEASE:=2

STRIP:=true

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=aarch64_generic
endif

ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
endif

PKG_FILE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/api.tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=openwrt api
	URL:=https://github.com/3wlh/
	DEPENDS:=@(aarch64||x86_64)
endef

define Package/$(PKG_NAME)/description
  openwrt api.
endef

define Build/Prepare
	if [ ! -f $(DL_DIR)/$(PKG_FILE) ] ; then \
		wget -q $(PKG_URL) -O $(DL_DIR)/$(PKG_FILE); \
	fi
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	tar -zxvf $(DL_DIR)/$(PKG_FILE) -C $(PKG_BUILD_DIR)
endef

define Download/$(PKG_NAME)
	URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/
	URL_FILE:=$(PKG_NAME)-$(PKG_ARCH)
	FILE:=$(PKG_NAME)-$(PKG_ARCH)
	HASH:=$(PKG_HASH)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME)-$(PKG_ARCH) $(1)/usr/sbin/$(PKG_NAME)
endef

# $(eval $(call Download,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
