TARGET := iphone:clang:latest:16.0
ARCHS := arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := phoneosm

phoneosm_FILES = Tweak.x
phoneosm_FRAMEWORKS = UIKit Foundation Contacts

include $(THEOS_MAKE_PATH)/tweak.mk
