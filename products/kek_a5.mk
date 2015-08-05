# Check for target product
ifeq (kek_a5,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_a5
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/htc/a5/cm.mk)

endif
