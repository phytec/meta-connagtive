SUMMARY = "Phytec's Connagtive IoT Device Suite Provisioning Image"
DESCRIPTION = "no graphics support in this image"
LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES += "allow-empty-password empty-root-password"

IMAGE_INSTALL = " \
    packagegroup-machine-base \
    packagegroup-core-boot \
    openssh \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-sks-openssl-tpm2", "",  d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-sks-pkcs11-tpm2", "", d)} \
    chrony \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-sks-provision-tpm2", "", d)} \
    coreutils \
    keyutils \
    util-linux \
    e2fsprogs \
    tzdata \
    iproute2 \
    provision-tpm \
"

IMAGE_INSTALL_append_mx6 = " firmwared"
IMAGE_INSTALL_append_mx6ul = " firmwared"
