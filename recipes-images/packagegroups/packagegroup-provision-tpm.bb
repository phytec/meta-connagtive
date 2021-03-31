DESCRIPTION = "Packagegroup for PKCS11 with TPM2."
LICENSE = "MIT"

inherit packagegroup

SUMMARY_packagegroup-pkcs11-tpm2 = "PKCS11 with TPM 2.0 support"

RDEPENDS_${PN} = " \
    tpm2-tools \
"
