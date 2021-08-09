#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2021 PHYTEC Messtechnik GmbH

set -e
trap end EXIT
end() {
    if [ "$?" -ne 0 ]; then
        echo "Failed provisioning to TPM!" 1>&2
    fi
}

USEHSM=1
CA_P12=""
CA_ROOT=""
HSMCERT_LABEL=""
HSM_USER_PIN=""

# Variable declaration
CA_DIR=$(mktemp -d -t tpm2tmpca.XXXXXX)

tpm2pkcs11tool='pkcs11-tool --module /usr/lib/libtpm2_pkcs11.so.0'
hsmpkcs11tool='pkcs11-tool --module /usr/lib/opensc-pkcs11.so'

# Generate SO-PIN
TPM_SOPIN=$(tpm2_getrandom --hex 8 | tr -dc 0-9)
TPM_PIN=$(cat /sys/devices/soc0/soc_uid | head -c 7)

USAGE="\
Usage:  $(basename $0) --p12init P12CONTAINER ROOTCA
        $(basename $0) --hsminit HSMLABEL HSMPIN
        $(basename $0) --csrequest
        $(basename $0) --writeca DEVICECA SUBCA ROOTCA
        $(basename $0) --clear

Initially provision certificate and key to a TPM.

Options:
  --p12init             Initialization with a PKCS#12 container
    P12CONTAINER        Path to PKCS#12 container with certificate and
                        private key
    ROOTCA              Path to root CA certificate

  --hsminit             Initialization with a HSM
    HSMLABEL            Label for certificate and key in HSM
    HSMPIN              HSM user PIN

  --csrrequest          Create keypair and Certificate signing request

  --writeca             Write Certificates to the TPM
    DEVICECA            Path to device CA certificate
    SUBCA               Path to intermediate CA certificate
    ROOTCA              Path to root CA certificate

  -c |--clear           Clear the TPM and any generated metadata

  -h | --help           Print this help

"

# Create Dev UID
setup_devuid() {
    read_ekcerttpm
    ekid=$(openssl x509 -noout -serial -in "${CA_EKCERT}" | cut -d '=' -f 2 | tr '[A-Z]' '[a-z]')
    DEV_UID="$(printf "%x%x" "$(date +%Y)" "$(date +%j)")${ekid}"
    len=`expr 20 - ${#DEV_UID}`
    let "len=len/2"
    [ $len -gt 0 ] && DEV_UID="${DEV_UID}$(tpm2_getrandom --hex ${len})"
    [ `expr ${#DEV_UID} % 2` -ne 0 ] && DEV_UID="${DEV_UID}$(tpm2_getrandom --hex 1 | cut -c 1)"
    export DEV_UID=$(echo ${DEV_UID} | tr '[A-Z]' '[a-z]')
    if [ ${#DEV_UID} -gt 20 ]; then
        echo "[ERROR] DEV_UID is too long"
        exit 1
    fi
}

# Create Device Common Name
setup_devcn() {
    soc=$(cat /sys/devices/soc0/soc_id | tr -d '.')
    export DEV_CN="PHY-${soc}-${DEV_UID}"
    if [ ${#DEV_CN} -gt 32 ]; then
        echo "[ERROR] DEV_CN is too long"
        exit 1
    fi
}

# Init Root Certificate
setup_caroot() {
    export ROOTCA_PEM="${CA_DIR}/rootca.pem"
    if [ $USEHSM -eq 0 ] && [ -f "${CA_ROOT}" ]; then
        cp ${CA_ROOT} ${ROOTCA_PEM}
    elif [ $USEHSM -eq 1 ]; then
        $hsmpkcs11tool -r -y cert -a "${HSMCERT_LABEL}root" -o ${CA_DIR}/rootca.der
        openssl x509 -inform DER -in ${CA_DIR}/rootca.der -outform PEM -out ${ROOTCA_PEM}
    else
        exit 5
    fi
}
# With Testing Intermediate CA from PKCS#12 container
setup_casub() {
    export CA_PEM="${CA_DIR}/subca.pem"
    if [ $USEHSM -eq 0 ] && [ -f "${CA_P12}" ]; then
        export CA_KEY="${CA_DIR}/subca.key"
        # Extract CA
        openssl pkcs12 -in "${CA_P12}" -out "${CA_PEM}" -clcerts -nokeys
        # Extract Keys
        openssl pkcs12 -in "${CA_P12}" -out "${CA_KEY}" -nocerts -nodes
    elif [ $USEHSM -eq 1 ]; then
        $hsmpkcs11tool -r -y cert -a ${HSMCERT_LABEL} -o "${CA_DIR}/subca.der"
        openssl x509 -inform DER -in "${CA_DIR}/subca.der" -outform PEM -out "${CA_PEM}"
    else
        exit 4
    fi
    # make the DB
    touch "${CA_DIR}/index.txt"
    touch "${CA_DIR}/index.txt.attr"

    echo "${DEV_UID}" > "${CA_DIR}/serial"

    LINEPRIVKEY=""
    if [ ${USEHSM} -eq 0 ]; then
        LINEPRIVKEY="private_key      = ${CA_KEY}"
    fi
    cat > "${CA_DIR}/ssl.cnf" <<EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

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
certificate      = ${CA_PEM}
default_days     = 32850
default_md       = sha256
policy           = policy_any
x509_extensions  = v3_client
string_mask      = utf8only
${LINEPRIVKEY}

[ policy_any ]
commonName          = supplied
organizationName    = match
localityName        = match
countryName         = match
stateOrProvinceName = match

[ v3_client ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints        = critical, CA:false
keyUsage                = critical, digitalSignature, keyAgreement
extendedKeyUsage        = critical, clientAuth
authorityInfoAccess     = OCSP;URI:http://ocsp.aws.esec-experts.com
crlDistributionPoints   = @crl_section

[crl_section]
URI.1 = http://crl.aws.esec-experts.com/OSBG1-REVOCATION_LIST.rev.der

[ engine_section ]
pkcs11  = pkcs11_section

[ pkcs11_section ]
engine_id       = pkcs11
MODULE_PATH     = /usr/lib/opensc-pkcs11.so
init            = 0
EOF
}

# Create openssl conf for CSR creation
create_csrconf() {
    cat > "${CA_DIR}/csrtpm.cnf" <<EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
MODULE_PATH = /usr/lib/libtpm2_pkcs11.so.0
PIN=myuserpin
init = 0

[ req ]
prompt              = no
distinguished_name  = req_dn
string_mask         = nombstr

[ req_dn ]
CN  = ${DEV_CN}
C   = DE
ST  = Rheinland-Pfalz
L   = Mainz
O   = PHYTEC
EOF
}

# Read EK Cert from TPM
read_ekcerttpm() {
    export CA_EKCERT="${CA_DIR}/ek_cert.pem"
    RSA_EK_CERT_NV_INDEX=0x01C00002
    NV_SIZE=$(tpm2_nvreadpublic ${RSA_EK_CERT_NV_INDEX} | grep size | awk ' {print $2}')
    tpm2_nvread --hierarchy owner --size ${NV_SIZE} --output "${CA_EKCERT}.der" ${RSA_EK_CERT_NV_INDEX}
    openssl x509 -inform DER -outform PEM -text -in "${CA_EKCERT}.der" -out "${CA_EKCERT}"
}

create_keycsr() {
    # Create CSR Conf
    create_csrconf

    # make path for tpm2-pkcs11 metadata
    mkdir -p /mnt/config/tpm2/pkcs11 --mode=775

    # TPM Remote Attestation
    tss2_provision

    # Init Token for Device Certificate
    $tpm2pkcs11tool --init-token --label=iotdm --so-pin=${TPM_SOPIN}
    # Set user pin
    $tpm2pkcs11tool --label="iotdm" --init-pin --so-pin ${TPM_SOPIN} --pin ${TPM_PIN}
    # Create Keypair for Device Certificate
    $tpm2pkcs11tool --label="iotdm-keypair" --login --pin=${TPM_PIN} --keypairgen --usage-sign --key-type EC:prime256v1 -d 1
    # Create CSR
    openssl req -config "${CA_DIR}/csrtpm.cnf" -new -engine pkcs11 -keyform engine -key "pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;object=iotdm-keypair;type=private;pin-value=${TPM_PIN}" -out "${CA_DIR}/devcsr.pem"

}

create_certs(){
    # Create Sub-CA
    setup_casub
    # Create Root CA
    setup_caroot
    # Create Device Cert
    if [ $USEHSM -eq 1 ]; then
        openssl ca -config "${CA_DIR}/ssl.cnf" -batch -engine pkcs11 -keyform engine -keyfile "slot_0-label_${HSMCERT_LABEL}" -in "${CA_DIR}/devcsr.pem" -out "${CA_DIR}/devcrt.pem" -passin pass:${HSM_USER_PIN}
    else
        openssl ca -config "${CA_DIR}/ssl.cnf" -batch -in "${CA_DIR}/devcsr.pem" -out "${CA_DIR}/devcrt.pem"
    fi

}


write_certsssh(){
    if [ $# -eq 3 ]; then
        # Write Device Cert
        $tpm2pkcs11tool -w "${1}" -y cert -a iotdm-cert --pin ${TPM_PIN} -d 2
        # Write Sub CA Cert
        $tpm2pkcs11tool -w "${2}" -y cert -a iotdm-subcert --pin ${TPM_PIN} -d 3
        # Write root CA cert
        $tpm2pkcs11tool -w "${3}" -y cert -a iotdm-rootcert --pin ${TPM_PIN} -d 4

        #ssh keys
        mkdir -p /mnt/config/.ssh --mode=750
        ssh-keygen -t ecdsa -b 521 -f /mnt/config/.ssh/id_ecdsa -N "" -q
    else
        echo "[ERROR] Wrong number of parameters"
        exit 1
    fi
}

setup_devuid
setup_devcn

ARGS=$(getopt -o 'hc' -l 'help,p12init::,hsminit::,csrrequest,writeca::,clear' -- "$@") || exit
eval set -- "$ARGS"
unset ARGS

while true; do
    case $1 in
    (-h|--help)
        echo "$USAGE"
        exit 0
        ;;
    (--p12init)
        shift 2
        echo "p12 init"
        USEHSM=0
        CA_P12=$2
        CA_ROOT=$3
        create_keycsr
        create_certs
        write_certsssh ${CA_DIR}/devcrt.pem ${CA_PEM} ${ROOTCA_PEM}
        exit 0
        ;;
    (--hsminit)
        shift 2
        echo "hsm init"
        USEHSM=1
        HSMCERT_LABEL=$2
        HSM_USER_PIN=$3
        create_keycsr
        create_certs
        write_certsssh ${CA_DIR}/devcrt.pem ${CA_PEM} ${ROOTCA_PEM}
        exit 0
        ;;
    (--csrrequest)
        echo "key csr"
        create_keycsr
        echo "Please send Certificate Signing Request"
        echo "${CA_DIR}/devcsr.pem"
        echo "to support@phytec.de"
        exit 0
        ;;
    (--writeca)
        shift 2
        echo "write certs"
        write_certsssh $2 $3 $4
        exit 0
        ;;
    (-c|--clear)
        echo "clear"
        tpm2_clear
        rm -rf /mnt/config/tpm2/*
        rm -rf /mnt/config/.ssh/*
        rm -rf /tmp/tpm2tmpca*
        exit 0
        ;;
    (--)
        shift
        break;;
    (*)
        exit 1;;
    esac
done
