#add protection shield level
#shieldlow - shieldmedium - shieldhigh
DISTRO_FEATURES += "protectionshield"
PROTECTION_SHIELD_LEVEL = "shieldmedium"
OVERRIDES_append = ":protectionshield:${PROTECTION_SHIELD_LEVEL}"

#password or authenticator for console and sshd
CONNAGTIVE_ROOT_AUTHENTICATION = "password"

# Set phytec-dev-ca version 1.2 as default
PREFERRED_VERSION_phytec-dev-ca = "1.2"
