SUMMARY = "LED blink test"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://blink-led.service \
    file://blink-led \
"

SYSTEMD_SERVICE_${PN} = "blink.service"

BLINK_COLOR = "led-red"

do_install() {
    install -d ${D}/${bindir}
    sed -i -e "s/@COLOR@/${BLINK_COLOR}/g" ${WORKDIR}/blink-led
    install -m 0755 ${WORKDIR}/blink-led ${D}/usr/bin/

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/blink-led.service ${D}${systemd_unitdir}/system/
}

FILES_${PN} = " \
    ${bindir}/blink-led \
    ${systemd_unitdir}/system/blink-led.service \
"
