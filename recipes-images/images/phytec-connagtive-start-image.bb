SUMMARY = "Phytec's Connagtive IoT Device Suite start image"
DESCRIPTION = "no graphics support in this image"
LICENSE = "MIT"
inherit core-image

require recipes-images/images/security/setrootpassword.inc

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_INSTALL = " \
    packagegroup-machine-base \
    packagegroup-core-boot \
    packagegroup-update \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-openssl-tpm2", "",  d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-pkcs11-tpm2", "", d)} \
    packagegroup-connagtive-base \
"

IMAGE_INSTALL_append_mx6 = " firmwared"
IMAGE_INSTALL_append_mx6ul = " firmwared"
