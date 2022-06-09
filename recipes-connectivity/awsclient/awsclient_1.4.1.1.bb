SUMMARY = "The AWS IoT client establishes a connection to AWS IoT, executes jobs and sends status information."

LICENSE = "CLOSED"

SRC_URI = "\
    https://github.com/iot-device-suite/meta-connagtive-device-suite/releases/download/v${PV}/awsclient_${PV}_${TARGET_ARCH} \
    file://awsclient.service \
    file://awsclient.timer \
"

SRC_URI[md5sum] = "d24df9d5e7ea3bb079b9240345d9f5c4"
SRC_URI[sha256sum] = "6d9708a8a773a5041e4f480a11ad7af49a97918b3632c35bf9ad17dc05907997"

DEPENDS = "curl glib-2.0 json-glib openssl"

inherit systemd

SYSTEMD_SERVICE_${PN} = "awsclient.timer"

do_install () {
    install -d ${D}${bindir}/
    install -m 0755 ${WORKDIR}/awsclient_${PV}_${TARGET_ARCH} ${D}${bindir}/awsclient

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/awsclient.service ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/awsclient.timer ${D}${systemd_unitdir}/system/
}

FILES_${PN} += " \
    ${systemd_unitdir}/system/awsclient.service \
    ${systemd_unitdir}/system/awsclient.timer \
"

INSANE_SKIP_${PN}_append = "already-stripped"
