# Check for target product
ifeq (kek_yuga,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_yuga
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/sony/yuga/cm.mk)

endif
