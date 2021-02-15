FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-include-configs-Change-A-B-system-partitions.patch \
    file://0002-include-configs-Enable-booting-A-B-system-by-default.patch \
"
