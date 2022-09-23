SUMMARY = "Phytec's Connagtive IoT Device Suite Test Image Migration"
DESCRIPTION = "Migration Image from zeus to hardknott"
LICENSE = "MIT"

require recipes-images/images/phytec-connagtive-test-image.bb

IMAGE_INSTALL += " \
    migration-zeus-to-hardknott \
"
