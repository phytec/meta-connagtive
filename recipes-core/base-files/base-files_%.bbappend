FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

SRC_URI += " \
    file://fstab \
    file://welcome-esec-iotdm.sh \
"

dirs755_append = " ${sysconfdir}/profile.d"

do_install_append() {
    install -m 0755 ${WORKDIR}/welcome-esec-iotdm.sh ${D}${sysconfdir}/profile.d/welcome-esec-iotdm.sh
}
