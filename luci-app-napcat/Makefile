include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-napcat
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-napcat
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=NapCat QQ Bot for LuCI
  # DEPENDS:=+docker
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/luci-app-napcat/install
	# 1. 安装LuCI控制器
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/napcat.lua $(1)/usr/lib/lua/luci/controller/
	chmod 755 $(1)/usr/lib/lua/luci/controller/napcat.lua  # 设置755权限
	
	# 2. 安装CBI配置页面
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luasrc/model/cbi/napcat.lua $(1)/usr/lib/lua/luci/model/cbi/
	chmod 755 $(1)/usr/lib/lua/luci/model/cbi/napcat.lua  # 设置755权限
	
	# 3. 安装视图页面
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/napcat
	$(INSTALL_DATA) ./luasrc/view/napcat/status.htm $(1)/usr/lib/lua/luci/view/napcat/
	chmod 755 $(1)/usr/lib/lua/luci/view/napcat/status.htm  # 设置755权限
	
	# 4. 安装UCI配置文件
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/napcat $(1)/etc/config/
	chmod 755 $(1)/etc/config/napcat  # 设置755权限
	
	# 5. 安装init.d启动脚本
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/napcat $(1)/etc/init.d/
	chmod 755 $(1)/etc/init.d/napcat  # 设置755执行权限
	
	# 6. 安装翻译文件
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./po/zh-cn/napcat.po $(1)/usr/lib/lua/luci/i18n/napcat.zh-cn.po
	chmod 755 $(1)/usr/lib/lua/luci/i18n/napcat.zh-cn.po  # 设置755权限
	
	# 7. 强制设置所有者为root
	chown -R root:root $(1)/usr/lib/lua/luci/
	chown -R root:root $(1)/etc/config/
	chown -R root:root $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,luci-app-napcat))