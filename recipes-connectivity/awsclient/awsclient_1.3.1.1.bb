SUMMARY = "The AWS IoT client establishes a connection to AWS IoT, executes jobs and sends status information."

LICENSE = "CLOSED"

SRC_URI = "\
    https://github.com/osb-cc-esec/meta-esec-awsclient/releases/download/v${PV}/awsclient_${PV}_${TARGET_ARCH} \
    file://awsclient.service \
    file://awsclient.timer \
"

SRC_URI[md5sum] = "99dbe3ae2f2bddda6a07bdb6899719a4"
SRC_URI[sha256sum] = "6c0582ae36573b867e85c2405e7f938b78562d0b99aec46301eae549b66dbea2"

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
