# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
include $(TOPDIR)/rules.mk

PKG_NAME:=page-static
BIN_NAME:=page.cgi
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=aarch64_generic
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
endif

BIN_FILE:=$(BIN_NAME)
BIN_URL:=https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_NapCat_Api/NapCat_Api-linux-$(PKG_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(BIN_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	SUBMENU:=System
	TITLE:=$(PKG_NAME)
	URL:=https://github.com/3wlh
	DEPENDS:=@(aarch64||x86_64) +libstdcpp
endef

define Package/$(PKG_NAME)/description
Post request to local webpage to return page.
endef

define Download/Files
	echo -e "\033[1;32m Download：$(BIN_URL)\033[0m"
	if [ ! -f $(PKG_BUILD_DIR)/$(BIN_FILE) ] ; then \
		wget -q $(BIN_URL) -O $(PKG_BUILD_DIR)/$(BIN_FILE); \
	fi
endef

define Build/Prepare
	echo -e "\033[31m Prepare：$(PKG_ARCH)\033[0m"
	mkdir -pm 775 $(PKG_BUILD_DIR)
	$(call Download/Files)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(BIN_NAME) $(1)/www/cgi-bin/$(BIN_NAME)
	chmod -R 755 $(1)/www/cgi-bin/$(BIN_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))