require recipes-images/bundles/phytec-base-bundle.inc

RAUC_SLOT_rootfs = "phytec-connagtive-test-migration-zeus-to-hardknott-image"

# RAUC Bundle Format from zeus
RAUC_BUNDLE_FORMAT = "plain"
RAUC_KEY_FILE = "${CERT_PATH}/rauc/private/development-1.key.pem"
RAUC_CERT_FILE = "${CERT_PATH}/rauc/development-1.cert.pem"
