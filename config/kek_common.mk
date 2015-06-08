# kek version
KEKVERSION := $(shell echo $(KEK_VERSION) | sed -e 's/^[ \t]*//;s/[ \t]*$$//;s/ /./g')
BOARD := $(subst kek_,,$(TARGET_PRODUCT))
KEK_BUILD_VERSION := kek_$(BOARD)_$(KEKVERSION)_$(shell date +%Y%m%d-%H%M%S)
PRODUCT_NAME := $(TARGET_PRODUCT)

# Set the board version
CM_BUILD := $(BOARD)
