FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

CONNAGTIVE_ROOT_AUTHENTICATION ??= "password"

do_install_append() {
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
