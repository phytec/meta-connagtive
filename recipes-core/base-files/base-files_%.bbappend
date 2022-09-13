FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

SRC_URI += " \
    file://welcome-connagtive.sh \
"

dirs755_append = " ${sysconfdir}/profile.d"

do_install_append() {
    install -m 0755 ${WORKDIR}/welcome-connagtive.sh ${D}${sysconfdir}/profile.d/welcome-connagtive.sh
    ln -s /mnt/config ${D}/config
    ln -s /mnt/app ${D}/app
}
