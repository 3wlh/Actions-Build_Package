# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
include $(TOPDIR)/rules.mk

PKG_NAME:=status-port
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
LUCI_TITLE:=app for status-port
LUCI_LANG:=zh-cn

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=admin
	ATEGORY:=Administration
	TITLE:=Status Port Overview (status/overview)
	URL:=https://github.com/3wlh
endef

define Package/$(PKG_NAME)/description
	Status Port Overview (status/overview).
endef

define Compress/jsmin
	echo -e "\033[31mInstall:jsmin\033[0m"
	wget -O jsmin.c https://raw.githubusercontent.com/douglascrockford/JSMin/refs/heads/master/jsmin.c
	sudo gcc -o /usr/local/bin/jsmin jsmin.c
	cd js && jsmin < port.js > port.min.js && mv port.min.js 29_port.js && \
	rm -rf port.js && cd -
	
endef

define Build/Prepare
	$(call Compress/jsmin)
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) -fr js $(PKG_BUILD_DIR)
	chmod -R 644 $(PKG_BUILD_DIR)/js/*
endef

define Package/$(PKG_NAME)/postinst
[ -n "${IPKG_INSTROOT}" ] || { rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	exit 0
}
endef

define Build/Compile
	touch $(PKG_BUILD_DIR)/.built
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/status/include
	$(CP) $(PKG_BUILD_DIR)/js/* $(1)/www/luci-static/resources/view/status/include/
endef


# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))