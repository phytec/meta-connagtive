SUMMARY = "Install whitelist for Connagtive IoT Device Suite"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://download_whitelist.txt \
    file://command_whitelist.txt \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/aws/config
    install -m 0644 ${WORKDIR}/download_whitelist.txt ${D}${sysconfdir}/aws/config/download_whitelist.txt
    install -m 0644 ${WORKDIR}/command_whitelist.txt ${D}${sysconfdir}/aws/config/command_whitelist.txt
}

# Do not create debug/devel packages
PACKAGES = "${PN}"

FILES_${PN} += "\
    ${sysconfdir}/aws/config/download_whitelist.txt \
    ${sysconfdir}/aws/config/command_whitelist.txt \
"
