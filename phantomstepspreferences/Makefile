TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PhantomStepsPreferences

PhantomStepsPreferences_FILES = pspRootListController.m
PhantomStepsPreferences_FRAMEWORKS = UIKit
PhantomStepsPreferences_PRIVATE_FRAMEWORKS = Preferences
PhantomStepsPreferences_INSTALL_PATH = /Library/PreferenceBundles
PhantomStepsPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
