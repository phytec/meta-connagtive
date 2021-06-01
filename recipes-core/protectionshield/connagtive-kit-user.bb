SUMMARY = "User access for the Connagtive IoT Device Suite platform"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

REQUIRED_DISTRO_FEATURES = "protectionshield"
inherit distro_features_check
inherit systemd

SYSTEMD_SERVICE_${PN} = "connagtive-kit-user.service"

SRC_URI = " \
    file://setpassword.sh \
    file://connagtive-kit-user.service \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/connagtive-kit-user.service ${D}${systemd_unitdir}/system/connagtive-kit-user.service

    install -d ${D}${bindir}
    install -m 0755 ${S}/setpassword.sh ${D}${bindir}/setpassword
}

# Do not create debug/devel packages
PACKAGES = "${PN}"

FILES_${PN} += "\
    ${systemd_unitdir}/system/connagtive-kit-user.service \
"

# Runtime packages used in 'connagtive-remote'
RDEPENDS_${PN} = " \
    sudo \
    google-authenticator-libpam \
    pam-google-authenticator \
    qrencode \
"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
