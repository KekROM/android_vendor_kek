KEK_ANDROID_VERSION := 6.0
TARGET_KEK_DEVICE := $(subst cm_,,$(TARGET_PRODUCT))
KEK_VERSION := $(KEK_ANDROID_VERSION)-$(shell date -u +%Y%m%d)-$(TARGET_KEK_DEVICE)

PRODUCT_PROPERTY_OVERRIDES += \
  ro.kek.version=$(KEK_VERSION)
