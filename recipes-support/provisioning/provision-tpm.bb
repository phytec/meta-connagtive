SUMMARY = "Provisioning tools for Connagtive IoT Device Suite platform"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
    file://provision-tpm.sh \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0500 ${S}/provision-tpm.sh ${D}${bindir}/provision-tpm
}

FILES_${PN} = " \
    ${bindir}/provision-tpm \
"
RDEPENDS_${PN} = " \
    util-linux \
    tpm2-tools \
"
