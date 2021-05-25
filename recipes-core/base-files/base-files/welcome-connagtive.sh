#!/bin/sh
echo "Welcome to your PHYTEC Board with support"
echo "for the Connagtive IoT Device Suite Platform"
echo "OnBoarding state:"
if [ $(/usr/bin/jq .awsclient < /mnt/config/aws/config/esec.config | grep start | wc -l) -eq 0 ]; then
    echo "NOT yet onboarded"
    echo "Please start the phytec-board-config tool first!"
else
    echo "Successfully onboarded"
fi
