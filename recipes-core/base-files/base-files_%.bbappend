FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

SRC_URI += " \
    ${@bb.utils.contains("DISTRO_FEATURES", "connagtive-provisioning", "", "file://welcome-connagtive.sh", d)} \
"

dirs755_append = " ${@bb.utils.contains("DISTRO_FEATURES", "connagtive-provisioning", "", "${sysconfdir}/profile.d", d)}"

do_configure_append_connagtive-provisioning() {
    # Because fstab is always present in SRC_URI, we cannot prevent
    # fetching our custom fstab, if it exits in FILESEXTRAPATHS. We have
    # to manually remove the lines that bother us for the provisioning
    # image here.
    sed -i -e '/\/mnt\/config/d' -e '/\/mnt\/app/d' ${S}/fstab
}

do_install_append() {
    case "${DISTRO_FEATURES}" in
        *connagtive-provisioning*) ;;
        *)
            install -m 0755 ${WORKDIR}/welcome-connagtive.sh ${D}${sysconfdir}/profile.d/welcome-connagtive.sh ;;
    esac
}
