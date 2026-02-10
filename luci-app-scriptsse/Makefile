include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-scriptsse
PKG_VERSION:=1.0
PKG_RELEASE:=$(shell date +%Y%m%d)
KG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=system
	CATEGORY:=System
	SUBMENU:=System Tools
	TITLE:=LuCI support for netconfig
	PKGARCH:=all
	DEPENDS:=+luci-base +sse_server-static
endef

define Package/$(PKG_NAME)/description
    A LuCI support for netconfig
endef

define Build/Prepare
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	mkdir -p $(PKG_BUILD_DIR)
	chmod -R 755 ./luasrc ./root
	$(CP) ./root $(PKG_BUILD_DIR)
	$(CP) ./luasrc $(PKG_BUILD_DIR)
endef

define Build/Compile
    touch $(PKG_BUILD_DIR)/.built
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))