# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
include $(TOPDIR)/rules.mk

PKG_NAME:=sse-msg-static
BIN_NAME:=sse_msg
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
BIN_URL:=https://github.com/3wlh/Actions-Build_Source/releases/download/$(BIN_NAME)/$(BIN_NAME)-$(PKG_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(BIN_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=system
	CATEGORY:=System
	SUBMENU:=System
	TITLE:=$(PKG_NAME)
	URL:=https://github.com/3wlh
	DEPENDS:=@(aarch64||x86_64) +libstdcpp +bash
endef

define Package/$(PKG_NAME)/description
Execute shell commands and push them to the web page in real time via SSE.
endef

define Download/Files
	echo -e "\033[1;32m Download：$(BIN_URL)\033[0m"
	if [ ! -f $(PKG_BUILD_DIR)/$(BIN_FILE) ] ; then \
		wget -q $(BIN_URL) -O $(PKG_BUILD_DIR)/$(BIN_FILE); \
	fi
endef

define Build/Prepare
	echo -e "\033[1;32m Prepare：$(PKG_ARCH)\033[0m"
	mkdir -pm 775 $(PKG_BUILD_DIR)
	$(call Download/Files)
	chmod -R 755 $(PKG_BUILD_DIR)
endef

define Build/Compile
	touch $(BUILD_DIR)/$(PKG_NAME).built
endef

define Package/$(PKG_NAME)/install
	echo -e "\033[1;32m install \033[0m"
	$(INSTALL_DIR) $(1)/usr/share/ssemsg
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(BIN_FILE) $(1)/usr/share/ssemsg/
	chmod -R 755 $(1)/usr/share/ssemsg
endef

$(eval $(call BuildPackage,$(PKG_NAME)))