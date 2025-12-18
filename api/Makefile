# Copyright (C) 2020-2022 3wlh <https://github.com/3wlh>

include $(TOPDIR)/rules.mk

PKG_NAME:=api
PKG_VERSION:=1.0
PKG_RELEASE:=20220422
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x86_64
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=i386
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsel
endif
ifeq ($(ARCH),mips)
	PKG_ARCH:=mips
endif
ifeq ($(ARCH),armeb)
	PKG_ARCH:=armeb
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm
endif
ifeq ($(ARCH),arm64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),powerpc)
	PKG_ARCH:=powerpc
endif
ifeq ($(ARCH),powerpc64)
	PKG_ARCH:=powerpc64le
endif

PKG_FILE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/api/$(PKG_NAME).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=openwrt api
	URL:=https://github.com/3wlh
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

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME)-$(PKG_ARCH) $(1)/sbin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))