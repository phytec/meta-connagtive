SUMMARY = "The AWS IoT client establishes a connection to AWS IoT, executes jobs and sends status information."

LICENSE = "CLOSED"

SRC_URI = "\
    https://git.osb-connagtive.com/iot/public/awsclient-releases/uploads/f36bf06aa3cb7a5bb40a0ebf86f19a86/awsclient_${PV}_${TARGET_ARCH} \
    file://awsclient.service \
    file://awsclient.timer \
"

SRC_URI[md5sum] = "7cf0988fc82f2d67a8495561cd6ca3ed"
SRC_URI[sha256sum] = "83ce772d795eed684da49ab04c794fd9c054f1d3e72955be2ecc1d447e18261a"

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
