FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'emmc', 'file://system_emmc.conf', 'file://system_nand.conf', d)} \
    file://is-parent-active \
    file://appfs.rules \
"

do_install_prepend() {
	sed -i -e 's!@LIBDIR@!${libdir}!g' -e 's!@PN@!${PN}!g' ${WORKDIR}/appfs.rules
}

do_install_append() {
    install -d ${D}${libdir}/${PN}/
    install -d ${D}${sysconfdir}/udev/rules.d/
    install -m 755 ${WORKDIR}/is-parent-active ${D}${libdir}/${PN}/
    install -m 644 ${WORKDIR}/appfs.rules ${D}${sysconfdir}/udev/rules.d/
}

FILES_${PN} += " \
    ${libdir}/${PN}/is-parent-active \
    ${sysconfdir}/udev/rules.d/appfs.rules \
"
