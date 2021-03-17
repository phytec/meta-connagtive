#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2021 PHYTEC Messtechnik GmbH

usage="
Usage: $(basename $0) OPTION

Print information about the current hardware.

One of the following options can be selected at a time:
  -c, --compatible        Device tree compatible of the machine
  -m, --machine           Hardware machine name
  -n, --simno             SIM number
  -s, --serial            Serial number
  -v, --machine-version   Hardware machine version
"

case "$1" in
	-c|--compatible)
		cut -f 1 -d '' /proc/device-tree/compatible
		;;
	-m|--machine)
		cat /etc/hostname
		;;
	-v|--machine-version)
		cat /etc/hostname | rev | cut -d '-' -f 1 | rev
		;;
	-s|--serial)
		echo "0x$(openssl x509 -noout -serial -in /mnt/config/aws/certs/devcert.pem | cut -d '=' -f 2 | awk '{print tolower($0)}')"
		;;
	-n|--simno)
		echo ""
		;;
	*)
		echo "$usage"
		;;
esac
