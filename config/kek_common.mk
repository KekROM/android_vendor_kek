# kek version
BOARD := $(subst kek_,,$(TARGET_PRODUCT))
KEK_VERSION := alpha
KEK_BUILD_VERSION := $(KEK_VERSION)-$(shell date +%Y%m%d)-$(BOARD)
PRODUCT_NAME := $(TARGET_PRODUCT)

# Chromium Prebuilt
ifeq ($(PRODUCT_PREBUILT_WEBVIEWCHROMIUM),yes)
-include prebuilts/chromium/$(TARGET_DEVICE)/chromium_prebuilt.mk
endif

# Set the board version
CM_BUILD := $(BOARD)
