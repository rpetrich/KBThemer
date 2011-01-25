TWEAK_NAME = KBThemer
KBThemer_FILES = KBThemer.m
KBThemer_FRAMEWORKS = Foundation UIKit CoreGraphics

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
