do_install_append () {
    rm ${D}${sysconfdir}/${PN}/config.conf
    ln -s /mnt/config/hawkbit/config.cfg ${D}${sysconfdir}/rauc-hawkbit-updater/config.conf
}
