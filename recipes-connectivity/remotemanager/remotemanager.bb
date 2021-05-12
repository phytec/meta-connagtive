SUMMARY = "Remote SSH Manager."

LICENSE = "CLOSED"

SRC_URI = "\
    file://remotemanager.sh \
    file://remotemanager.service \
"

RDEPENDS_${PN} += " openssh"

inherit systemd

SYSTEMD_SERVICE_${PN} = "remotemanager.service"

do_install () {
    install -d ${D}${bindir}/
    install -m 0755 ${WORKDIR}/remotemanager.sh ${D}${bindir}/remotemanager

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/remotemanager.service ${D}${systemd_unitdir}/system/
}

FILES_${PN} += " \
    ${systemd_unitdir}/system/remotemanager.service \
"
