SUMMARY = "Phytec's headless image"
DESCRIPTION = "no graphics support in this image"
LICENSE = "MIT"
inherit core-image

include security/userauthentication.inc
include security/simple-fitimage.inc

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_INSTALL = " \
    packagegroup-machine-base \
    packagegroup-core-boot \
    packagegroup-update \
    openssh \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-openssl-tpm2", "",  d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-pkcs11-tpm2", "", d)} \
    coreutils \
    keyutils \
    lvm2 \
    util-linux \
    e2fsprogs \
    fscryptctl \
    cryptsetup \
    tzdata \
    ntp \
    curl \
    iproute2 \
    esec-provisioning \
"

IMAGE_INSTALL_append_mx6 = " firmwared"
IMAGE_INSTALL_append_mx6ul = " firmwared"
