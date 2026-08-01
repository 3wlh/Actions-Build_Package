include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-napcat
BIN_NAME:=napcat
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
KG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif


BIN_FILE:=$(BIN_NAME)
BIN_URL:=https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_docker_web/docker_web-$(PKG_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=system
	CATEGORY:=System
	SUBMENU:=System Tools
	TITLE:=LuCI support for napcat
	PKGARCH:=all
	DEPENDS:=+libstdcpp
endef

define Package/$(PKG_NAME)/description
    A LuCI support for napcat
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
	$(CP) ./luasrc $(PKG_BUILD_DIR)
	chmod -R 755 $(PKG_BUILD_DIR)	
endef

define Build/Compile
    touch $(BUILD_DIR)/$(PKG_NAME).built
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(BIN_FILE) $(1)/usr/share/$(BIN_NAME)/
	$(CP) ./files/docker.json $(1)/usr/share/$(BIN_NAME)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))