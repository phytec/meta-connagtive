SUMMARY = "PHYTEC board information tool"
HOMEPAGE = "https://www.phytec.de"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://phytec-board-info.sh \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 755 ${S}/phytec-board-info.sh ${D}${bindir}/${BPN}
}

FILES_${PN} += " \
    ${bindir}/${BPN} \
"
RDEPENDS_${PN} = " \
    openssl-bin \
"
