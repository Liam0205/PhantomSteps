
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = com.apple.HealthKit


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PhantomSteps

PhantomSteps_FILES = Tweak.x
PhantomSteps_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += phantomstepspreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
