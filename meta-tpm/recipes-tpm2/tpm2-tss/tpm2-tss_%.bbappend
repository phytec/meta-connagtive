FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += " curl json-c"

PACKAGECONFIG[fapi] = "--enable-fapi,json-c "

FILES_${PN} += "\
    ${sysconfdir}/* \
    ${sysconfdir}/tpm2-tss/* \
    ${sysconfdir}/sysusers.d/* \
"
