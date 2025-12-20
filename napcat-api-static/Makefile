# Copyright (C) 2020-2022 3wlh <https://github.com/3wlh>

include $(TOPDIR)/rules.mk

PKG_NAME:=napcat-api-static
BIN_NAME:=napcat-api
PKG_VERSION:=1.0.0
PKG_RELEASE:=$(shell date +%Y%m%d)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

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
	SECTION:=net
	CATEGORY:=Network
	TITLE:=$(PKG_NAME)
	URL:=https://github.com/3wlh
	DEPENDS:=@(aarch64||x86_64)
endef

define Package/$(PKG_NAME)/description
NapCat Robot call the API.
endef

define Build/Prepare
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	if [ ! -f $(PKG_BUILD_DIR)/$(PKG_FILE) ] ; then \
		wget -q $(PKG_URL) -O $(PKG_BUILD_DIR)/$(PKG_FILE); \
	fi
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/napcat/
/etc/config/napcat
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/napcat.init $(1)/etc/init.d/napcat
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/napcat.config $(1)/etc/config/napcat
	$(INSTALL_DIR) $(1)/etc/napcat
	$(INSTALL_CONF) $(CURDIR)/files/config.yaml $(1)/etc/napcat/napcat.yaml
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_FILE) $(1)/usr/sbin/$(BIN_NAME)
	chmod -R 755 $(1)/usr/sbin/$(BIN_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))