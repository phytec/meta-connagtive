SUMMARY = "Blink system LED depending on RAUC status"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = " \
    file://blink-led.service \
    file://blink-led.timer \
    file://blink-led \
"

SYSTEMD_SERVICE_${PN} = "blink-led.timer"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/blink-led ${D}${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/blink-led.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/blink-led.timer ${D}${systemd_system_unitdir}
}

FILES_${PN} = " \
    ${bindir}/blink-led \
    ${systemd_system_unitdir}/blink-led.service \
    ${systemd_system_unitdir}/blink-led.timer \
"
