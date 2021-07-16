require recipes-images/images/phytec-connagtive-start-image.bb

SUMMARY =  "This image is designed to show development of a Qt application \
            running on the eglfs single application backend."

IMAGE_FEATURES += "splash ssh-server-openssh hwcodecs qtcreator-debug"

LICENSE = "MIT"

inherit distro_features_check populate_sdk_qt5

IMAGE_INSTALL += "\
    packagegroup-machine-base \
    packagegroup-core-boot \
    packagegroup-update \
    \
    packagegroup-gstreamer \
    \
    qt5-opengles2-test \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'qtwayland qtwayland-plugins weston weston-init', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11 wayland', 'weston-xwayland', '', d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-openssl-tpm2", "",  d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "tpm2", "packagegroup-pkcs11-tpm2", "", d)} \
"

IMAGE_INSTALL_remove_mx6ul = "\
    qt5-opengles2-test \
"
