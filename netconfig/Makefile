include $(TOPDIR)/rules.mk

PKG_NAME:=netconfig
PKG_VERSION:=1.0
PKG_RELEASE:=$(shell date +%Y%m%d)
KG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=system
	CATEGORY:=System
	SUBMENU:=System Tools
	TITLE:=LuCI support for netconfig
	PKGARCH:=all
	DEPENDS:=+luci-base
endef

define Package/$(PKG_NAME)/description
    A LuCI support for netconfig
endef

define Build/Prepare
	echo -e "\033[31mARCH：$(PKG_ARCH)\033[0m"
	mkdir -p $(PKG_BUILD_DIR)
	# 复制源码到编译目录（无空格路径）
	chmod -R 755 ./luasrc ./root
	$(CP) ./root $(PKG_BUILD_DIR)
	$(CP) ./luasrc $(PKG_BUILD_DIR)
endef

define Build/Compile
    touch $(PKG_BUILD_DIR)/.built
endef

define Package/$(PKG_NAME)/install
	# 手动指定安装路径（绝对路径，无拼接）
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))