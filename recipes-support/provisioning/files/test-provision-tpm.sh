#!/usr/bin/env bash
#===============================================================================
#
#  provision-tpm.sh
#
#  Copyright (C) 2021 by PHYTEC Messtechnik GmbH
#  All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2 as published by
#  the Free Software Foundation.
#
#===============================================================================

printf "======================================\n" > /dev/console
printf "PHYTEC TPM2 Test Provision Version 0.2\n" > /dev/console
printf "======================================\n" > /dev/console

# Get CPU UID
get_cpu_uid() {
    val=$(cat /sys/devices/soc0/soc_uid)
    echo "${val}"
}

set -e
trap end EXIT
end() {
    if [ "$?" -ne 0 ]; then
        printf "PHYTEC-TPM2-Provision:fail! \n" > /dev/console
    fi
}

# Variable declaration
CA_DIR=`mktemp -d -t tpm2tmpca.XXXXXX`
export CA_DIR

tpm2pkcs11tool='pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so'
# Generate SO-PIN
TPM_SOPIN=$(tpm2_getrandom --hex 8 | tr -dc 0-9)
TPM_PIN=$(get_cpu_uid | head -c${1:-7})

# With Testing Intermediate CA from PKCS#12 container
setup_casubtest() {
    CA_P12="${PWD}/Testing_Sub_CA.p12"
    export CA_PEM="${CA_DIR}/subca.pem"
    export CA_KEY="${CA_DIR}/subca.key"
    # Extract CA
    openssl pkcs12 -in "${CA_P12}" -out "${CA_PEM}" -clcerts -nokeys
    # Extract Keys
    openssl pkcs12 -in "${CA_P12}" -out "${CA_KEY}" -nocerts -nodes
    # make the DB
    touch "${CA_DIR}"/index.txt
    touch "${CA_DIR}"/index.txt.attr

    read_ekcerttpm
    ekid=$(get_serial_ekcert)
    randid=$(tpm2_getrandom --hex 2)
    export DEV_UID="${ekid}${randid}"
    echo "${DEV_UID}" > "${CA_DIR}"/serial
cat > ${CA_DIR}/ssl.cnf <<EOF
[ default ]
ca               = x_ca
dir              = .

[ca]
default_ca       = x_ca

[x_ca]
dir              = ${CA_DIR}
database         = ${CA_DIR}/index.txt
new_certs_dir    = ${CA_DIR}
serial           = ${CA_DIR}/serial
private_key      = ${CA_DIR}/subca.key
certificate      = ${CA_DIR}/subca.pem
default_days     = 32850
default_md       = sha256
policy           = policy_any

[ req ]
prompt             = no
encrypt_key        = no
# base request
distinguished_name = req_distinguished_name

[ policy_any ]
commonName             = optional
description            = optional
EOF
}

# Create openssl conf for CSR creation
create_csrconf() {

cat > ${CA_DIR}/csrtpm.cnf <<EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
MODULE_PATH = /usr/lib/pkcs11/libtpm2_pkcs11.so
PIN=myuserpin
init = 0

[ req ]
distinguished_name = req_dn
string_mask = utf8only
utf8 = yes

[ req_dn ]
commonName = Device0
EOF
}

# Read EK Cert from TPM
read_ekcerttpm() {
    export CA_EKCERT="${CA_DIR}/ek_cert.pem"
    RSA_EK_CERT_NV_INDEX=0x01C00002
    NV_SIZE=`tpm2_nvreadpublic ${RSA_EK_CERT_NV_INDEX} | grep size | awk ' {print $2}'`
    tpm2_nvread --hierarchy owner --size ${NV_SIZE} --output ${CA_EKCERT}.der ${RSA_EK_CERT_NV_INDEX}
    openssl x509 -inform DER -outform PEM -text -in ${CA_EKCERT}.der -out ${CA_EKCERT}
}

# Get Serial Number from CERT
get_serial_ekcert() {
    val=$(openssl x509 -noout -serial -in "${CA_EKCERT}" | cut -d'=' -f2)
    echo "${val}"
}


# Create Sub-CA
setup_casubtest
create_csrconf

# TPM Remote Attestation
tss2_provision

# Init Token for Device Certificate
$tpm2pkcs11tool --init-token --label=iotdm --so-pin=${TPM_SOPIN}
# Set user pin
$tpm2pkcs11tool --label="iotdm" --init-pin --so-pin ${TPM_SOPIN} --pin ${TPM_PIN}
# Create Keypair for Device Certificate
$tpm2pkcs11tool --label="iotdm-keypair" --login --pin=${TPM_PIN} --keypairgen --usage-sign --key-type EC:prime256v1
# Create CSR
val=$(cat /proc/device-tree/model | cut -d ' ' -f 2)
DEV_CN="${val}-${DEV_UID}"
openssl req -config "${CA_DIR}/csrtpm.cnf" -new -subj "/CN=${DEV_CN}" -engine pkcs11 -keyform engine -key "pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;object=iotdm-keypair;type=private;pin-value=${TPM_PIN}" -out "${CA_DIR}/devcsr.pem"
# Create Device Cert
openssl ca -config "${CA_DIR}/ssl.cnf" -batch -in "${CA_DIR}/devcsr.pem" -out "${CA_DIR}/devcrt.pem"
#Write Device Cert
p11tool --login --write --load-certificate="${CA_DIR}/devcrt.pem" --label=iotdm-cert "pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;pin-value=${TPM_PIN}"
# Write Sub CA Cert
p11tool --login --write --load-certificate="${CA_PEM}" --ca --label=iotdm-subcert "pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;pin-value=${TPM_PIN}"

printf "PHYTEC-TPM2-Provision:pass! \n" > /dev/console
