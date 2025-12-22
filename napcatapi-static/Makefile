# Copyright (C) 2020-2022 3wlh <https://github.com/3wlh>

include $(TOPDIR)/rules.mk

PKG_NAME:=napcatapi-static
BIN_NAME:=napcatapi
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
	if [ ! -f $(DL_DIR)/$(PKG_FILE) ] ; then \
		wget -q $(PKG_URL) -O $(DL_DIR)/$(PKG_FILE); \
	fi
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	cp -f $(DL_DIR)/$(PKG_FILE) -C $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/napcatapi/
/etc/config/napcatapi
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/etc/napcatapi
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_FILE) $(1)/usr/sbin/$(BIN_NAME)
	chmod -R 755 $(1)/usr/sbin/$(BIN_NAME)
	$(INSTALL_BIN) ./files/napcatapi.init $(1)/etc/init.d/napcatapi
	$(INSTALL_CONF) ./files/napcatapi.config $(1)/etc/config/napcatapi
	$(INSTALL_CONF) ./files/config.yaml $(1)/etc/napcatapi/config.yaml
	#$(CP) ./files/config.yaml $(1)/etc/napcatapi/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))