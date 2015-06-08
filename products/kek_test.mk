# Check for target product
ifeq (kek_test,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_test
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/lol/test/cm.mk)

endif
