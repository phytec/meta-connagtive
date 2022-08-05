#!/bin/sh

# VERSION TAG
version="v3.1.0"

set -Eeo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
	cat<<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-V] [-c config.file] [-k privatekey.file]

RemoteManager - IoT Suite Remote Access Client

This script creates a tunnel to a public SSH jump host managed by OSB connagtive.
The login at the server must be activated in iot-suite Dashboard, otherwise the incoming
connection will not be allowed on the remote server (jump host).

Available options:

-h, --help      Print this help and exit
-v, --version   Print script version
-V, --verbose   Print script more verbose messages
-c, --config    Configuration File
-k, --key       Private Keyfile to use (will override the variable PrivateKey from config file, if exists)
EOF
	exit
}

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
	# script cleanup here
}

parse_params() {
	# default values of variables set from params
	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-V | --verbose) set -x ;;
		-v | --version) echo $version ; exit 0 ;;
		-c | --config)
			ConfigFile="${2-}"
			shift ;; # Config File
		-k | --key)
			PrivateKeyCommandline="${2-}"
			shift ;; # Private key file overriding paramter in the Config File
		-p | --param) # example named parameter
			param="${2-}"
			shift ;;
		-?*)
			echo "ERROR: Unknown option: $1"
			exit 1 ;;
		*) break ;;
		esac
		shift
	done
	return 0
}

parse_params "$@"

# script logic here

echo "Read parameters:"
echo "- config: ${ConfigFile}"
echo "- key: ${PrivateKeyCommandline}"


echo Start RemoteManager
# Does the key file exist
if [ ! -z $ConfigFile -a -e $ConfigFile ] # file exists
then
	echo "Config file exists: $ConfigFile"
else
	echo "ERROR: Config file not found: $ConfigFile"
	echo aborting
	exit 2
	# Exiting
fi

while true
do
	if . ${ConfigFile}
	then
		if [ -z $ServerSshPort ] # If server port not specified
		then
			ServerSshPort=22
		fi
		if [ -z $HostPort ] # if host port not specified
		then
			HostPort=22
		fi

		echo "Checking Key file"
		# Manual Key input
		if [ ! -z $PrivateKeyCommandline ] # Key was given by commandline, non empty string
		then
			echo "Manual key was specified: $PrivateKeyCommandline"
			if [ -f $PrivateKeyCommandline ] # file exists
			then
				# Override the command parameter from config file
				echo "Key exists --> using commandline private key as override"
				PrivateKey=$PrivateKeyCommandline
			fi
		fi

		# Does the key file exist
		if [ -f $PrivateKey ] # file does exist
		then
			echo "Private key exists: " $PrivateKey
		else
			echo "ERROR: Private key not found: $PrivateKey"
			exit 3
		fi

		if $ReverseConnectionActive
		then
			echo "connecting to $ServerURL as $DeviceName via SSH"
			echo "closing connection in $ConnectionSleepTimeSec seconds"
			ssh_command="ssh -i $PrivateKey -o ConnectTimeout=10 -o ServerAliveInterval=5 -o StrictHostKeyChecking=no -p $ServerSshPort -R $ServerReversePort:localhost:$HostPort $DeviceName@$ServerURL sleep $ConnectionSleepTimeSec"
			echo "ssh command: ${ssh_command}"
			if ${ssh_command}
			then
				echo "ssh connection closed successfully"
			else
				echo "ssh connection failed, sleeping ${IdleSleepTimeSec} seconds" >&2
				sleep ${IdleSleepTimeSec}
			fi
		else
			echo "Reverse Connection inactive"
			echo "sleeping for ${IdleSleepTimeSec} seconds"
			sleep ${IdleSleepTimeSec}
		fi
	else
		exit 1
	fi
done
