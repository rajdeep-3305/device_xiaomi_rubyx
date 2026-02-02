#
# SPDX-FileCopyrightText: 2023-2025 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/rubyx/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_rubyx
PRODUCT_DEVICE := rubyx
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := ruby

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Redmi/ruby_global/ruby:14/UP1A.230620.001/OS2.0.10.0.UMOMIXM:user/release-keys \
    SystemName=ruby_global \
    SystemDevice=ruby

# Axion Stuff
TARGET_ENABLE_BLUR := true
TARGET_INCLUDE_VIPERFX := true
AXION_CAMERA_REAR_INFO := 200/50,8,2
AXION_CAMERA_FRONT_INFO := 16
AXION_MAINTAINER := Casanova.
AXION_PROCESSOR := MediaTek_Dimensity_1080_(MT6877V)_(6nm)
TARGET_INCLUDES_LOS_PREBUILTS := true
