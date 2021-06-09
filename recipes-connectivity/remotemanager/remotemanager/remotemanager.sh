#!/bin/sh

ConfigFile="./RemoteManager.conf"

while true
do
	if . $ConfigFile
	then
		if [ -z $ServerSshPort ]
		then
			ServerSshPort=22
		fi

		if [ -z $HostPort ]
		then
			HostPort=22
		fi

		if $ReverseConnectionActive
		then
			echo "connecting to $ServerURL as $DeviceName via SSH"
			echo "closing connection in $ConnectionSleepTimeSec seconds"
			if ssh -i "$PrivateKey" -o "ConnectTimeout=5" -o "ServerAliveInterval=5" -o "StrictHostKeyChecking=no" -p $ServerSshPort -R $ServerReversePort:localhost:$HostPort $DeviceName@$ServerURL sleep $ConnectionSleepTimeSec
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
	else
		exit 1
	fi
done
