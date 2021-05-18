SUMMARY = "Device registration to ESEC IoT Device Manager plattform"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://phytec-board-config.sh \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0555 ${S}/phytec-board-config.sh ${D}${bindir}/phytec-board-config
}

FILES_${PN} = " \
    ${bindir}/phytec-board-config \
"
# Runtime packages used in 'esec-device-onboarding.sh'
RDEPENDS_${PN} = " \
    libnewt \
    whiptail \
    jq \
"
