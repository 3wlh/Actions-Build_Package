# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-napcatapi
BIN_NAME:=napcatapi
PKG_VERSION:=1.0.0
PKG_RELEASE:=$(shell date +%Y%m%d)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
LUCI_TITLE:=LuCI app for napcatapi
# LUCI_DEPENDS:=+napcatapi-static
LUCI_LANG:=zh-cn

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif

PKG_FILE:=$(PKG_NAME)-$(PKG_VERSION)
PKG_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/$(BIN_NAME)/$(BIN_NAME)_$(PKG_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=Applications
	TITLE:=$(PKG_NAME)
	URL:=https://github.com/3wlh
	DEPENDS:=@(aarch64||x86_64)
endef

define Package/$(PKG_NAME)/description
	NapCat Robot call the API.
endef

define Build/Prepare
	git clone https://github.com/openwrt/po2lmo.git && cd po2lmo
	make clean && make
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	if [ ! -f $(DL_DIR)/$(PKG_FILE) ] ; then \
		wget $(PKG_URL) -O $(DL_DIR)/$(PKG_FILE); \
	fi
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) -fr root $(PKG_BUILD_DIR)
	$(CP) -fr po $(PKG_BUILD_DIR)
	$(CP) -f $(DL_DIR)/$(PKG_FILE) $(PKG_BUILD_DIR)
	chmod -R 755 $(PKG_BUILD_DIR)
	find "${PKG_BUILD_DIR}/po/zh-cn/" -name "*.po" -exec po2lmo {} "${PKG_BUILD_DIR}/napcatapi.zh-cn.lmo" \;
	echo -e "\033[31mlmo：${po}\033[0m"
	ls $(PKG_BUILD_DIR)/po/zh-cn
	ls $(PKG_BUILD_DIR)
endef

define Build/Compile
	touch $(PKG_BUILD_DIR)/.built
endef

define Package/$(PKG_NAME)/conffiles
	/etc/napcatapi/
	/etc/config/napcatapi
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_FILE) $(1)/usr/sbin/$(BIN_NAME)
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/
endef


# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))