# Check for target product
ifeq (kek_bacon,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_bacon
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/oneplus/bacon/cm.mk)

endif
