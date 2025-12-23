include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for NapCat QQ Bot (Docker)
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-base
PKG_NAME:=luci-app-napcat
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# 调用BuildPackage - OpenWRT构建系统标准流程
$(eval $(call BuildPackage,$(PKG_NAME)))