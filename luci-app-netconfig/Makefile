include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netconfig
PKG_VERSION:=1.0
PKG_RELEASE:=$(shell date +%Y%m%d)
LUCI_LANG:=zh-cn
KG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

LUCI_TITLE:=LuCI Demo netconfig          # 应用名称
LUCI_PKGARCH:=all                          # 架构无关
LUCI_DEPENDS:=+luci-base			     # 依赖
LUCI_DESCRIPTION:=A demo for LuCI app dev  # 描述

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/feeds/luci/luci.mk

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/files
	# 复制源码到编译目录（无空格路径）
	cp -r ./luasrc $(PKG_BUILD_DIR)/files/
	cp -r ./root $(PKG_BUILD_DIR)/files/
endef



define Package/$(PKG_NAME)/install
	# 手动指定安装路径（绝对路径，无拼接）
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/root/usr/sbin/netconfig.sh $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/luasrc/controller/netconfig.lua $(1)/usr/lib/lua/luci/controller/
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=Applications
	TITLE:=LuCI Demo netconfig
	DEPENDS:=$(DEPENDS)
	PKGARCH:=$(PKGARCH)
endef


$(eval $(call BuildPackage,$(PKG_NAME)))