ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MenuSupportSettings
MenuSupportSettings_FILES = Preference.m
MenuSupportSettings_CLAGS = -fobjc-arc
MenuSupportSettings_INSTALL_PATH = /Library/PreferenceBundles
MenuSupportSettings_FRAMEWORKS = UIKit
MenuSupportSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MenuSupport.plist$(ECHO_END)
