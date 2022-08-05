SUMMARY = "Remote SSH Manager."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

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
