# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-photopea
BIN_NAME:=photopea
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
LUCI_TITLE:=LuCI app for photopea
LUCI_LANG:=zh-cn

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif

BIN_FILE:=$(BIN_NAME)
BIN_URL:=https://github.com/3wlh/Actions-Build_Docker-image/releases/download/$(BIN_NAME)/$(BIN_NAME)_$(PKG_ARCH)
WEB_FILE:=www.photopea.com.tar.gz
WEB_URL:=https://github.com/3wlh/Actions-Build_Docker-image/releases/download/$(BIN_NAME)/www.photopea.com.tar.gz
FONTS_FILE:=fonts.tar.gz
FONTS_URL:=https://github.com/3wlh/Actions-Build_Docker-image/releases/download/$(BIN_NAME)/fonts.tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(BIN_NAME)

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

define Download/Files
	echo -e "\033[32m Download：$(PKG_ARCH) \033[0m"
	if [ ! -f $(PKG_BUILD_DIR)/$(BIN_FILE) ] ; then \
		wget $(BIN_URL) -O $(PKG_BUILD_DIR)/$(BIN_FILE); \
	fi
	if [ ! -f $(PKG_BUILD_DIR)/$(WEB_FILE) ] ; then \
		wget $(WEB_URL) -O $(PKG_BUILD_DIR)/$(WEB_FILE); \
	fi
	if [ ! -f $(PKG_BUILD_DIR)/$(FONTS_FILE) ] ; then \
		wget $(FONTS_URL) -O $(PKG_BUILD_DIR)/$(FONTS_FILE); \
	fi
	chmod -R 755 $(PKG_BUILD_DIR)
	ls $(PKG_BUILD_DIR)
endef

define Extract/Files
	echo -e "\033[1;32m Extract：Files \033[0m"
	test -d $(PKG_BUILD_DIR)/www.photopea.com || mkdir -p $(PKG_BUILD_DIR)/www.photopea.com
	tar -zxf $(WEB_FILE) -C $(PKG_BUILD_DIR)/www.photopea.com
	tar -zxf $(FONTS_FILE) -C $(PKG_BUILD_DIR)/www.photopea.com/rsrc/fonts	
endef

define Build/Po2lmo
	if [ ! -d "po2lmo" ]; then \
		git clone https://github.com/openwrt-dev/po2lmo.git && cd po2lmo; \
		make clean && make && sudo make install && cd - ;\
	fi
	$(foreach po,$(wildcard ./po/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Prepare
	echo -e "\033[1;32m Prepare：$(PKG_ARCH)\033[0m"
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(call Download/Files)
	$(call Extract/Files)
	$(call Build/Po2lmo)
	$(CP) -fr root $(PKG_BUILD_DIR)
	$(CP) -fr luasrc $(PKG_BUILD_DIR)
	chmod -R 755 $(PKG_BUILD_DIR)/$(PKG_NAME)
	ls $(PKG_BUILD_DIR)
endef

define Package/$(PKG_NAME)/postinst
[ -n "${IPKG_INSTROOT}" ] || { rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	/etc/init.d/rpcd reload 2>/dev/null
	/etc/init.d/ucitrack reload 2>/dev/null
	exit 0
}
endef

define Build/Compile
	touch $(BUILD_DIR)/$(PKG_NAME).built
endef

define Package/$(PKG_NAME)/conffiles
/etc/photopea/
/etc/config/photopea
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_FILE) $(1)/usr/sbin/$(PKG_FILE)
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/photopea.init $(1)/etc/init.d/photopea
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/photopea.config $(1)/etc/config/photopea
	$(INSTALL_DIR) $(1)/etc/photopea
	$(CP) -fr $(PKG_BUILD_DIR)/www.photopea.com $(1)/etc/photopea/photopea
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/photopea.uci-default $(1)/etc/uci-defaults/photopea	
endef


# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))