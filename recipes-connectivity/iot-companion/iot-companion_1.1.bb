SUMMARY = "IoT Companion - Commandline helper application"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://iot-companion.sh \
    file://iot-companion.config \
"

RDEPENDS_${PN} += " jq"

do_install () {
    install -d ${D}${bindir}/
    install -m 0755 ${WORKDIR}/iot-companion.sh ${D}${bindir}/iot-companion
    ln -sf iot-companion ${D}/usr/bin/iot

    install -d ${D}${sysconfdir}/aws/config
    install -m 0644 ${WORKDIR}/iot-companion.config ${D}${sysconfdir}/aws/config/iot-companion.config
}

FILES_${PN} += "\
    ${sysconfdir}/aws/config/iot-companion.config \
"
