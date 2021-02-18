# Copyright (C) 2021 Maik Otto <m.otto@phytec.de>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Provisioning Tools for ESEC IOTDM Plattform"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = " \
    file://test-provision-tpm.sh \
"

S = "${WORKDIR}"

do_install() {
    install -m 0500 test-provision-tpm.sh ${D}/home
}

FILES_${PN} += "/home"
