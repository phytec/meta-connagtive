SUMMARY = "Phytec's Connagtive IoT Device Suite Test Image"
DESCRIPTION = "no graphics support in this image"
LICENSE = "MIT"
inherit core-image

require recipes-images/images/security/setrootpassword.inc

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_INSTALL = " \
    packagegroup-machine-base \
    packagegroup-core-boot \
    packagegroup-update \
    openssh \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-openssl-tpm2", "",  d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-pkcs11-tpm2", "", d)} \
    chrony \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-provision-tpm", "", d)} \
    coreutils \
    keyutils \
    lvm2 \
    util-linux \
    e2fsprogs \
    fscryptctl \
    cryptsetup \
    tzdata \
    curl \
    iproute2 \
    awsclient \
    connagtive-provisioning \
    phytec-board-info \
    phytec-board-config \
    blink-led \
    remotemanager \
    ${@bb.utils.contains("DISTRO_FEATURES", "protectionshield", "connagtive-kit-user", "", d)} \
    connagtive-whitelist \
"

IMAGE_INSTALL_append_mx6 = " firmwared"
IMAGE_INSTALL_append_mx6ul = " firmwared"
