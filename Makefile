
TARGET := iphone:clang:14.5:14.5
INSTALL_TARGET_PROCESSES = com.apple.HealthKit

THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PhantomSteps

PhantomSteps_FILES = Tweak.x
PhantomSteps_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += phantomstepspreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
