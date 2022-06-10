#!/bin/sh

usage="
PHYTEC Onboarding Tool for Connagtive IoT Device Suite Platform
For More information: https://doc.iot-suite.io

Usage:  $(basename $0) [acceptcontract] [OPTION]

Example:
		$(basename $0)
		$(basename $0) acceptcontract --newaccount=<your mailing address>
		$(basename $0) acceptcontract --onboarding

One of the following options can be selected at a time:
  acceptcontract                            Accept the contract and no Interface
  -n, --newaccount=<your mailing address>   New account and Onboarding the device
                                            for Connagtive IoT Device Suite Platform
  -o, --onboarding                          Onboarding with existing account the device
                                            for Connagtive IoT Device Suite Platform
  -s, --sshlogin                            Change Authentication for SSH
  -c, --consolelogin                        Change Authentication for Console
  -h. --help                                This Help
"

INTERACTIVE=True
ESECCONTRACT=False

tpm2pkcs11tool='pkcs11-tool --module /usr/lib/libtpm2_pkcs11.so.0'
CONFIG_PATH="/mnt/config"
AWSCONFIG_PATH="${CONFIG_PATH}/aws"
AWSCONFIG_CERT="certs"
AWSCONFIG_CERTPATH="${AWSCONFIG_PATH}/${AWSCONFIG_CERT}"
AWSCONFIG_CONFPATH="${AWSCONFIG_PATH}/config"
ESECCONFIG="esec.config"
HAWKBITCONFIG_PATH="${CONFIG_PATH}/hawkbit/"
REMOTEMANAGER_PATH="${CONFIG_PATH}/esec/"
SSHPUBKEY_PATH="${CONFIG_PATH}/.ssh/"
AUTHENT_FILE="${REMOTEMANAGER_PATH}.google_authenticator"

TPM_PIN=$(cat /sys/devices/soc0/serial_number | head -c 7)

calc_wt_size() {
	# NOTE: it's tempting to redirect stderr to /dev/null, so supress error
	# output from tput. However in this case, tput detects neither stdout or
	# stderr is a tty and so only gives default 80, 24 values
	WT_HEIGHT=20
	WT_WIDTH=$(echo $COLUMNS)

	if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
		WT_WIDTH=80
	fi
	if [ "$WT_WIDTH" -gt 178 ]; then
		WT_WIDTH=120
	fi
	WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_about() {
	whiptail --msgbox "\
This tool provides a straightforward way of doing initial
configuration of your PHYTEC board for the
Connagtive IoT Device Suite at https://phytec.iot-suite.io.
For more information visit https://doc.iot-suite.io." $WT_HEIGHT $WT_WIDTH 1
	return $?
}

do_help() {
	whiptail --msgbox "\
For more information on how to use this tool
download any manuals and documentation from
https://www.phytec.de/support/downloads/.

For detailed documentation of the Connagtive
IoT Device Suite, visit https://doc.iot-suite.io." $WT_HEIGHT $WT_WIDTH 1
	return $?
}

do_contract() {
	if [ "$ESECCONTRACT" = False ] || [ $# -eq 1 ]; then
		box="--yesno"
		txta="Do you accept?"
		if [ "$ESECCONTRACT" = True ]; then
			box="--msgbox"
			txta="You have accepted this contract"
		fi
		whiptail --scrolltext ${box} "\
$(cat /usr/share/phytec-board-config/AGB_OSB-connagtive_EN)

you can also read the contract here:
https://www.connagtive.com/agb.html
${txta}" $WT_HEIGHT $WT_WIDTH
		if [ $? -eq 0 ] && [ "${box}" = --yesno ]; then
			set_eseccontract
		fi
	fi
}
#export all certs from tpm
do_extractcert() {
	mkdir -p ${AWSCONFIG_CERTPATH} --mode=777
	#dev cert
	$tpm2pkcs11tool -r -y cert -a iotdm-cert > ${AWSCONFIG_CERTPATH}/devcert.der
	openssl x509 -inform DER -in ${AWSCONFIG_CERTPATH}/devcert.der -outform PEM -out ${AWSCONFIG_CERTPATH}/devcert.pem
	# intermediate cert
	$tpm2pkcs11tool -r -y cert -a iotdm-subcert > ${AWSCONFIG_CERTPATH}/subcert.der
	openssl x509 -inform DER -in ${AWSCONFIG_CERTPATH}/subcert.der -outform PEM -out ${AWSCONFIG_CERTPATH}/subcert.pem
	cat ${AWSCONFIG_CERTPATH}/devcert.pem ${AWSCONFIG_CERTPATH}/subcert.pem > ${AWSCONFIG_CERTPATH}/cert.pem
	#root cert
	$tpm2pkcs11tool -r -y cert -a iotdm-rootcert > ${AWSCONFIG_CERTPATH}/rootcert.der
	openssl x509 -inform DER -in ${AWSCONFIG_CERTPATH}/rootcert.der -outform PEM -out ${AWSCONFIG_CERTPATH}/rootcert.pem

}

get_devcertserial () {
	DEV_SERIAL="0x$(openssl x509 -noout -serial -in ${AWSCONFIG_CERTPATH}/devcert.pem | cut -d '=' -f 2 | tr '[A-Z]' '[a-z]')"
}

do_awsconfig() {
	mkdir -p ${AWSCONFIG_CONFPATH} --mode=775
	mkdir -p ${HAWKBITCONFIG_PATH} --mode=775
	mkdir -p ${REMOTEMANAGER_PATH} --mode=775

	get_devcertserial
	FILE=${AWSCONFIG_CONFPATH}/config.json
	if [ ! -f "${FILE}" ]; then
		cat > ${FILE} <<EOF
{
  "endpoint": "aqbh9vo6udjdm-ats.iot.eu-central-1.amazonaws.com",
  "mqtt_port": 8883,
  "https_port": 443,
  "greengrass_discovery_port": 8443,
  "root_ca_relative_path": "${AWSCONFIG_CERT}/rootcert.pem",
  "device_certificate_relative_path": "${AWSCONFIG_CERT}/cert.pem",
  "openssl_engine": "/usr/lib/engines-1.1/pkcs11.so",
  "pkcs11_provider": "/usr/lib/libtpm2_pkcs11.so.0",
  "device_private_key_pkcs11_url":
  "pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;object=iotdm-keypair;type=private",
  "slot_user_pin": "${TPM_PIN}",
  "tls_handshake_timeout_msecs": 60000,
  "tls_read_timeout_msecs": 2000,
  "tls_write_timeout_msecs": 2000,
  "aws_region": "eu-central-1",
  "aws_access_key_id": "",
  "aws_secret_access_key": "",
  "aws_session_token": "",
  "client_id": "${DEV_SERIAL}",
  "thing_name": "${DEV_SERIAL}",
  "is_clean_session": true,
  "mqtt_command_timeout_msecs": 20000,
  "keepalive_interval_secs": 600,
  "minimum_reconnect_interval_secs": 1,
  "maximum_reconnect_interval_secs": 128,
  "maximum_acks_to_wait_for": 32,
  "action_processing_rate_hz": 5,
  "maximum_outgoing_action_queue_length": 32,
  "discover_action_timeout_msecs": 300000,
  "shadow_update_interval_secs": 0,

  "rauc_hawkbit_client_config_dir": "${HAWKBITCONFIG_PATH}",
  "rauc_hawkbit_client_config_file": "config.cfg",

  "remote_manager_config_dir": "${REMOTEMANAGER_PATH}",
  "remote_manager_config_file": "RemoteManager.conf",

  "ssh_pub_key_dir": "${SSHPUBKEY_PATH}",
  "ssh_pub_key_file": "id_ecdsa.pub",

  "isoconnect_app_config_dir": "",
  "isoconnect_app_config_file": "",
  "isoconnect_app_config_signature_file": "",

  "maintenance_task_temp_download_dir": "/tmp/",
  "maintenance_task_download_whitelist_path":
  "/etc/aws/config/download_whitelist.txt",
  "maintenance_task_command_whitelist_path":
  "/etc/aws/config/command_whitelist.txt",

  "desired_hawkbit_server_url": "",

  "shadow_commands": [
  ]
}
EOF
fi
}

do_esecawsconf() {
	FILE="${AWSCONFIG_CONFPATH}/${ESECCONFIG}"
	if [ ! -f "${FILE}" ]; then
		mkdir -p ${AWSCONFIG_CONFPATH} --mode=775
		cat > ${FILE} <<EOF
{
   "eseccontract" : {
     "accept" : "False",
     "timestamp" : ""
   },
   "onboarding" : {
     "state" : "",
     "timestamp" : ""
   },
   "awsclient": "stop"
}
EOF
	fi
	jsontxt=$(cat ${FILE})
	ESECCONTRACT=$(echo ${jsontxt} | jq .eseccontract.accept | sed -r 's/["]+//g')
}

set_eseccontract() {
	FILE="${AWSCONFIG_CONFPATH}/${ESECCONFIG}"
	ESECCONTRACT=True
	jsontxt=$(cat ${FILE})
	jsontxt=$(echo ${jsontxt} | jq --arg para accept --arg val "${ESECCONTRACT}" '.eseccontract[$para]  = $val')
	vdate=$(date)
	jsontxt=$(echo ${jsontxt} | jq --arg para timestamp --arg val "$vdate" '.eseccontract[$para] = $val')
	echo ${jsontxt} | jq . > ${FILE}
}

set_onboarded() {
	FILE="${AWSCONFIG_CONFPATH}/${ESECCONFIG}"
	jsontxt=$(cat ${FILE})
	jsontxt=$(echo ${jsontxt} | jq --arg para state --arg val "$1" '.onboarding[$para]  = $val')
	vdate=$(date)
	jsontxt=$(echo ${jsontxt} | jq --arg para timestamp --arg val "$vdate" '.onboarding[$para] =   $val')
	echo ${jsontxt} | jq . > ${FILE}
	set_awsclient start
	systemctl restart awsclient
}

set_awsclient(){
	FILE="${AWSCONFIG_CONFPATH}/${ESECCONFIG}"
	jsontxt=$(cat ${FILE})
	jsontxt=$(echo ${jsontxt} | jq --arg val "$1" '.awsclient  = $val')
	echo ${jsontxt} | jq . > ${FILE}
}

do_opensslconfig() {
	mkdir -p ${AWSCONFIG_CONFPATH} --mode=775
	FILE=${AWSCONFIG_CONFPATH}/openssl_curl.cnf
	export OPENSSL_CONF=${FILE}
	if [ ! -f "${FILE}" ]; then
		cat > ${FILE} <<EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
MODULE_PATH = /usr/lib/libtpm2_pkcs11.so.0
PIN = my_pin
init = 0
EOF
	fi
}

do_clearAWSCONFIG() {
	rm -r ${AWSCONFIG_PATH}
}

do_initAWSCONFIG(){
	do_opensslconfig
	do_extractcert
	do_awsconfig
	return 0
}

do_resetAWSCONFIG() {
	do_clearAWSCONFIG
	do_initAWSCONFIG
	return 0
}

do_onboarding() {
	awsrequest="https://devices.aws.esec-experts.com/ownership/token"
	if [ $# -eq 1 ]; then
		awsrequest="--request POST https://devices.aws.esec-experts.com/ownership/customer_account?customer_mail=$1"
	else
		do_contract
		if [ "$ESECCONTRACT" = False ]; then
			return 0
		fi
	fi
	do_initAWSCONFIG
	PRIVATEKEYURI="pkcs11:model=SLB9670;manufacturer=Infineon;token=iotdm;object=iotdm-keypair;type=private"
	response=$(curl --cacert ${AWSCONFIG_CERTPATH}/rootcert.pem --engine pkcs11 --key-type ENG --key "${PRIVATEKEYURI};pin-value=${TPM_PIN}" --cert ${AWSCONFIG_CERTPATH}/devcert.pem ${awsrequest})
	if [ $? -ne 0 ]; then
	   return 1
	fi
	if [ "$INTERACTIVE" = True ]; then
		#error check
		check=$(echo ${response} | jq .message)
		if [ "$check" = "\"Forbidden\"" ]; then
			return 2
		fi
		check=$(echo ${response} | jq .errorType)
		if [ ! -z "$check" ] && [ ! "$check" = null ]; then
			check=$(echo ${response} | jq .errorMessage)
			whiptail --msgbox "\
Error Message from IoT Device Manager
$check" $WT_HEIGHT $WT_WIDTH
			return 0
		fi
		if [ $# -eq 0 ]; then
			# get token
			set_onboarded tokendevice
			certserial=$(echo ${response} | jq .thing_name)
			token=$(echo ${response} | jq .token)
			valid=$(echo ${response} | jq .valid_until)
			whiptail --msgbox "\
Welcome to the Connagtive IoT Device Suite Platform
The next steps are:
 1) Login to your account on the Connagtive IoT Device
    Suite Platform https://phytec.iot-suite.io.
    If you do not have an account, then use
    option 1) New Account and Onboarding to register
 2) Add the device with this
    Unique device ID (UID) ${certserial}
    Token: ${token}
    Valid until: ${valid}
    to your account:
 3) Press 'Ok'. The awsclient will be
    restarted three times." $WT_HEIGHT $WT_WIDTH
		else
			# get user item
			set_onboarded accountdevice
			check=$(echo ${response} | jq .user_item.customer_name)
			whiptail --msgbox "\
Welcome ${check}
to the Connagtive IoT Device Suite Platform
The next steps are:
 1) Check your email account for a message
    from welcome@esec-experts.com
 2) Verify your email
 3) Login to your IoT Device Suite account
 4) Check the state of your device in
    your IoT Device Suite account" $WT_HEIGHT $WT_WIDTH
		fi
		do_restart_awsclient
	else
		if [ $# -eq 0 ]; then
			set_onboarded tokendevice
		else
			set_onboarded accountdevice
		fi
		echo "response: ${response}"
		echo "After a successful onboarding the awsclient needs to be rerun with 'systemctl restart awsclient' three times."
	fi
	do_getauthenticator
	return 0
}

do_newaccount() {
	do_contract
	if [ "${ESECCONTRACT}" = False ]; then
		return 0
	fi
	account=$(whiptail --inputbox "Your email address for the new account:" $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3)
	if [ $? -ne 0 ]; then
		return 1
	elif [ -z "$account" ]; then
		whiptail --msgbox "Error: your email address is empty!: $account. " $WT_HEIGHT $WT_WIDTH
		return 1
	fi
	do_onboarding $account
	return $val
}

do_restart_awsclient() {
	echo Restarting awsclient, this may take a while...
	systemctl restart awsclient
	systemctl restart awsclient
	systemctl restart awsclient
}

do_login() {
	login_state=$(awk '/common-auth/ { if (substr($1,1,1) ~ /^[# ]/ ) print 1; else print 0}' /etc/pam.d/${2})
	password_state="ON"
	google_state="OFF"
	if [ ${login_state} -eq 1 ]; then
		password_state="OFF"
		google_state="ON"
	fi
	login_newstate=$(whiptail --radiolist "Choose the login method for $1. (Select an item with the arrow keys and spacebar)" $WT_HEIGHT $WT_WIDTH 2 \
        "0" "Static Password" $password_state \
        "1" "One-time Password (IoT Device Suite platform)" $google_state 3>&1 1>&2 2>&3)
	RET=$?
	if [ $RET -eq 0 ]; then
		if [ ${login_state} -ne ${login_newstate} ]; then
			if [ ${login_newstate} -eq 0 ]; then
				do_login_password ${2}
			else
				do_login_authenticator ${2}
			fi
		fi
	fi
}

do_getauthenticator() {
	response=$(curl --cacert ${AWSCONFIG_CERTPATH}/rootcert.pem --engine pkcs11 --key-type ENG --key "${PRIVATEKEYURI};pin-value=${TPM_PIN}" --cert ${AWSCONFIG_CERTPATH}/devcert.pem https://devices.aws.esec-experts.com/ownership/ssh_keys)
	if [ $? -ne 0 ]; then
	   return 1
	fi
	devicekey=$(echo ${response} | jq .DEVICE_KEY | tr -d '"' | tr -d "=")
	scratchcode=$(echo ${response} | jq .SCRATCH_CODES | tr -d '"' | tr -d ',')
	cat > ${AUTHENT_FILE} <<EOF
${devicekey}
" RATE_LIMIT 3 30
" WINDOW_SIZE 17
" HOTP_COUNTER 1
$(echo ${scratchcode} | cut -d ' ' -f 2)
$(echo ${scratchcode} | cut -d ' ' -f 3)
$(echo ${scratchcode} | cut -d ' ' -f 4)
EOF
chmod 400 ${AUTHENT_FILE}
}

#parameter sshd or login
do_login_authenticator() {
	#set google authenticator for ssh
	sed -i '/pam_google_authenticator.so/s/^#//g' /etc/pam.d/$1
	sed -i '/common-auth/s/^/#/g' /etc/pam.d/$1
}

do_login_password() {
	#set Password for ssh
	sed -i '/common-auth/s/^#//g' /etc/pam.d/$1
	sed -i '/pam_google_authenticator.so/s/^/#/g' /etc/pam.d/$1
}

calc_wt_size
do_esecawsconf
#
# Command line options for non-interactive use
#
for i in $*
do
	case $i in
	-o|--onboarding)
		do_onboarding
		exit 0
		;;
	--newaccount=*)
		OPT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		do_onboarding $OPT
		exit 0
		;;
	-n)
		INTERACTIVE=True
		do_newaccount
		exit 0
		;;
	acceptcontract)
		set_eseccontract
		INTERACTIVE=False
		;;
	-s|sshlogin)
		do_login "SSH" "sshd"
		exit 0
		;;
	-c|consolelogin)
		do_login "Console" "login"
		exit 0
		;;
	-h|--help)
		echo "$usage"
		exit 0
		;;
	*)
		# unknown option
		;;
	esac
done

#
# Interactive use loop
#
if [ "$INTERACTIVE" = True ]; then
	while true; do
		FUN=$(whiptail --title "PHYTEC - Connagtive IoT Device Configuration Tool" --backtitle "$(tr -d '\0' < /proc/device-tree/model)" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
            "1 New Account and Onboarding" "" \
            "2 Onboarding with existing Account" "" \
            "3 Login Settings for Serial Console" "" \
            "4 Login Settings for SSH" "" \
            "5 Terms and Conditions" "" \
            "6 Help" "" \
            "7 About" "" 3>&1 1>&2 2>&3)
		RET=$?
		if [ $RET -eq 1 ]; then
			if [ ! -z "$FUN" ]; then
				echo "$FUN"
			fi
			exit 0
		elif [ $RET -eq 0 ]; then
			case "$FUN" in
			1\ *) do_newaccount ;;
			2\ *) do_onboarding ;;
			3\ *) do_login "Console" "login" ;;
			4\ *) do_login "SSH" "sshd" ;;
			5\ *) do_contract 1 ;;
			6\ *) do_help ;;
			7\ *) do_about ;;
			*) whiptail --msgbox "Programmer error: unrecognized option" $WT_HEIGHT $WT_WIDTH 1 ;;
			esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
		fi
	done
fi

