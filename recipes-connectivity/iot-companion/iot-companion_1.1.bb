SUMMARY = "IoT Companion - Commandline helper application"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://iot-companion.sh \
"

RDEPENDS_${PN} += " jq"

do_install () {
    install -d ${D}${bindir}/
    install -m 0755 ${WORKDIR}/iot-companion.sh ${D}${bindir}/iot-companion
    ln -sf iot-companion ${D}/usr/bin/iot
}