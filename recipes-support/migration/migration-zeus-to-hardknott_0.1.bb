SUMMARY = "Migration Tool for conversion from zeus to hardknott"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://migration.service \
    file://migration-zeus-to-hardknott.sh \
"

inherit systemd

SYSTEMD_SERVICE_${PN} = "migration.service"

do_install () {
    install -d ${D}${bindir}/
    install -m 0755 ${WORKDIR}/migration-zeus-to-hardknott.sh ${D}${bindir}/migration-zeus-to-hardknott

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/migration.service ${D}${systemd_unitdir}/system/
}

FILES_${PN} += " \
    ${systemd_unitdir}/system/migration.service \
"

RDEPENDS_${PN} = " \
    jq \
"
