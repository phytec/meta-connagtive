DESCRIPTION = "Packagegroup for connagtive demo images"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS_${PN} = " \
    openssh \
    chrony \
    coreutils \
    keyutils \
    lvm2 \
    util-linux \
    e2fsprogs \
    tzdata \
    curl \
    iproute2 \
    awsclient \
    phytec-board-config \
    phytec-board-info \
    blink-led \
    remotemanager \
    ${@bb.utils.contains("DISTRO_FEATURES", "protectionshield", "connagtive-kit-user", "", d)} \
    connagtive-whitelist \
"
