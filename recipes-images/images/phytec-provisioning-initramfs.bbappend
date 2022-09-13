IMAGE_FEATURES += "allow-empty-password empty-root-password"

IMAGE_INSTALL_append = " \
    provision-tpm \
"
