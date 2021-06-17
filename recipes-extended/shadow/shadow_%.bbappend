FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

CONNAGTIVE_ROOT_AUTHENTICATION ??= "password"

do_install_append() {
    if [ -f ${D}${sysconfdir}/pam.d/login ]; then
        echo "auth required pam_google_authenticator.so echo_verification_code no_increment_hotp [secret=/mnt/config/esec/.google_authenticator]" >> ${D}${sysconfdir}/pam.d/login

        if [ ${CONNAGTIVE_ROOT_AUTHENTICATION} = "password" ]; then
            sed -i '/common-auth/s/^#//g' ${D}${sysconfdir}/pam.d/login
            sed -i '/pam_google_authenticator.so/s/^/#/g' ${D}${sysconfdir}/pam.d/login
        elif [ ${CONNAGTIVE_ROOT_AUTHENTICATION} = "authenticator" ]; then
            sed -i '/pam_google_authenticator.so/s/^#//g' ${D}${sysconfdir}/pam.d/login
            sed -i '/common-auth/s/^/#/g' ${D}${sysconfdir}/pam.d/login
        fi
    fi
}
