# Check for target product
ifeq (kek_geehrc,$(TARGET_PRODUCT))

# Include Kek common configuration
PRODUCT_NAME := kek_geehrc
include vendor/kek/config/kek_common.mk

# Inherit CM device configuration
$(call inherit-product, device/lge/geehrc/cm.mk)

endif
