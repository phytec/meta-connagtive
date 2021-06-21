#!/bin/sh

WELCOME_TEXT="
Welcome to your PHYTEC Board with support for the Connagtive IoT Device Suite!
Onboarding state:"

print_not_onboarded() {
	echo -e "$WELCOME_TEXT \e[0;31mNOT ONBOARDED\e[0m (Please start \"phytec-board-config\" first)\n"
}

print_successfully_onboarded() {
	echo -e "$WELCOME_TEXT \e[0;32mSUCCESSFULLY ONBOARDED\e[0m\n"
}

if [ ! -e /mnt/config/aws/config/esec.config ]; then
	print_not_onboarded
elif [ $(/usr/bin/jq .awsclient < /mnt/config/aws/config/esec.config | grep start | wc -l) -eq 0 ]; then
	print_not_onboarded
else
	print_successfully_onboarded
fi
