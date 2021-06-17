FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

CONNAGTIVE_ROOT_AUTHENTICATION ??= "password"

SRC_URI_append = " file://sshd_check_keys_connagtive"

do_install_append() {
    install -D -m 0755 ${WORKDIR}/sshd_check_keys_connagtive ${D}${libexecdir}/${BPN}/sshd_check_keys

    sed -i -e 's:#ChallengeResponseAuthentication yes:ChallengeResponseAuthentication yes:' ${D}${sysconfdir}/ssh/sshd_config

    echo "auth required pam_google_authenticator.so echo_verification_code no_increment_hotp [secret=/mnt/config/esec/.google_authenticator]" >> ${D}${sysconfdir}/pam.d/sshd
    if [ ${CONNAGTIVE_ROOT_AUTHENTICATION} = "password" ]; then
        sed -i '/common-auth/s/^#//g' ${D}${sysconfdir}/pam.d/sshd
        sed -i '/pam_google_authenticator.so/s/^/#/g' ${D}${sysconfdir}/pam.d/sshd
    elif [ ${CONNAGTIVE_ROOT_AUTHENTICATION} = "authenticator" ]; then
        sed -i '/pam_google_authenticator.so/s/^#//g' ${D}${sysconfdir}/pam.d/sshd
        sed -i '/common-auth/s/^/#/g' ${D}${sysconfdir}/pam.d/sshd
    fi
}

FILES_${PN}-sshd += "${libexecdir}/${BPN}/sshd_check_keys_connagtive"
