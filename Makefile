ARCHS = arm64 arm64e
TARGET = iphone:clang:11.4:11.0
include $(THEOS)/makefiles/common.mk

SUBPROJECTS += pref
include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = MenuSupport
MenuSupport_FILES = Tweak.xm
MenuSupport_CFLAGS = -fobjc-arc
MenuSupport_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

before-all::
	$(ECHO_NOTHING)echo " coping header to theos linclude directory..."$(ECHO_END)
	$(ECHO_NOTHING)cp -a MenuSupport.h $(THEOS)/include/$(ECHO_END)

stage::
	mkdir -p $(THEOS_STAGING_DIR)/usr/include
	$(ECHO_NOTHING)cp -a MenuSupport.h $(THEOS_STAGING_DIR)/usr/include $(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
