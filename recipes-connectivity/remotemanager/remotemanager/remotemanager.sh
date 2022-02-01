#!/usr/bin/env bash

# VERSION TAG
version="v3.1.0"

#set -Eeuo pipefail
set -Eeo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat<<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-V] [-c config.file] [-k privatekey.file]

RemoteManager - IoT Suite Remote Access Client

This script creates a tunnel to a public SSH-Jump host managed by OSB connagtive. 
The login at the server must be activated in iot-suite Dashboard, otherwise the incoming 
connection will not be allowed on the remote server (jump host).

Available options:

-h, --help      Print this help and exit
-v, --version   Print script VERSION
-V, --verbose   Print script more verbose messages
-c, --config    Configuration File
-k, --key       Private Keyfile to use (will override $PrivateKey from config file, if exists) 
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -V | --verbose) set -x ;;
	  -v | --version) echo $version ; exit 0 ;;
    --no-color) NO_COLOR=1 ;;
    -c | --config) 
	  ConfigFile="${2-}"  
    shift ;; # Config File
    -k | --key) 
	  PrivateKeyCommandline="${2-}" 
    shift ;; # Private key file overriding paramter in the Config File
    -p | --param) # example named parameter
      param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  #[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}


parse_params "$@"
setup_colors

# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- config: ${ConfigFile}"
msg "- key: ${PrivateKeyCommandline}"


echo Start RemoteManager
# Does the key file exist
if [ -e $ConfigFile ] # file exists
then
    echo "Config file exists: $ConfigFile"
else 
    echo "Config file not found: $ConfigFile"
    echo aborting
    die "no config" 1
    # Exiting  
fi

while true
do
	if . $ConfigFile
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
		if [  -f $PrivateKey ] # file does exist
		then
			echo "Private key exists: " $PrivateKey
		else 
			echo "Private key not found: $PrivateKey"
			die
			# Exiting  
		fi

		if $ReverseConnectionActive
		then
			echo "connecting to $ServerURL as $DeviceName via SSH"
			echo "closing connection in $ConnectionSleepTimeSec seconds"
			echo "ssh command "ssh -i "$PrivateKey" -o "ConnectTimeout=10" -o "ServerAliveInterval=5" -o "StrictHostKeyChecking=no" -p $ServerSshPort -R $ServerReversePort:localhost:$HostPort $DeviceName@$ServerURL sleep $ConnectionSleepTimeSec
      if ssh -i "$PrivateKey" -o "ConnectTimeout=10" -o "ServerAliveInterval=5" -o "StrictHostKeyChecking=no" -p $ServerSshPort -R $ServerReversePort:localhost:$HostPort $DeviceName@$ServerURL sleep $ConnectionSleepTimeSec
			then
				echo "ssh connection closed successfully"
			else
				echo "ssh connection failed, sleeping $IdleSleepTimeSec seconds" >&2
				sleep $IdleSleepTimeSec
			fi
		else
			echo "Reverse Connection inactive"
			echo "sleeping for $IdleSleepTimeSec seconds"
			sleep $IdleSleepTimeSec
		fi
		# Reloading configfile if was upated after the last connection
		echo "----------------------------"
    echo "Reloading Config File"
		source $ConfigFile
	else
		exit 1
	fi
done
