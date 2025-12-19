# Copyright (C) 2020-2022 3wlh <https://github.com/3wlh>

include $(TOPDIR)/rules.mk

PKG_NAME:=page-static
BIN_NAME:=page.cgi
PKG_VERSION:=1.0.0
PKG_RELEASE:=$(shell date +%Y%m%d)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=aarch64_generic
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
endif

PKG_FILE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/$(BIN_NAME)/$(BIN_NAME).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_HASH:=skip

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

define Build/Prepare
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	if [ ! -f $(DL_DIR)/$(PKG_FILE) ] ; then \
		wget -q $(PKG_URL) -O $(DL_DIR)/$(PKG_FILE); \
	fi
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	tar -zxvf $(DL_DIR)/$(PKG_FILE) -C $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(BIN_NAME)-$(PKG_ARCH) $(1)/www/cgi-bin/$(BIN_NAME)
	chmod -R 755 $(1)/www/cgi-bin/$(BIN_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))