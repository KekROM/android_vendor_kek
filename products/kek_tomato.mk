# Check for target product
ifeq (kek_tomato,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_tomato
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/yu/tomato/cm.mk)

endif
