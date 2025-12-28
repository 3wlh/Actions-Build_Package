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

define Build/Prepare
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	mkdir -p $(PKG_BUILD_DIR)
	# 复制源码到编译目录（无空格路径）
	cp -fr ./luasrc $(PKG_BUILD_DIR)
	cp -fr ./root $(PKG_BUILD_DIR)
endef


define Package/$(PKG_NAME)/install
	# 手动指定安装路径（绝对路径，无拼接）
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/root/usr/sbin/netconfig.sh $(1)/usr/sbin/netconfig.sh
	chmod -R 755 $(1)/usr/sbin/netconfig.sh
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/controller/netconfig.lua $(1)/usr/lib/lua/luci/controller/netconfig.lua
	chmod -R 755 $(1)/usr/sbin/netconfig.sh
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=Applications
	TITLE:=LuCI Demo netconfig
endef


$(eval $(call BuildPackage,$(PKG_NAME)))