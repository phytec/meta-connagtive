#!/bin/sh

awsconfig="/mnt/config/aws/config/config.json"
awsconfig_zeus="/mnt/config/aws/config/config-zeus.json"

shadowcommands='[
        ["timer", "grep OnUnitActiveSec= /lib/systemd/system/awsclient.timer | grep -o [^=]*.$ | tr -d \"\\n\""],
        ["fs_cnf", "df | grep /mnt/config$ | tr -s \" \" | tr -d \"\\n\""],
        ["fs_app", "df | grep /mnt/app$ | tr -s \" \" | tr -d \"\\n\""],
        ["fs_root", "df | grep /$ | tr -s \" \" | tr -d \"\\n\""],
        ["up", "cat /proc/uptime | tr -d \"\\n\""],
        ["krn", "cat /proc/version | tr -d \"\\n\""],
        ["cpu", "cat /proc/loadavg | tr -d \"\\n\""],
        ["mem_a", "grep MemAvailable /proc/meminfo | tr -s \" \" | cut -d \" \" -f2 | tr -d \"\\n\""],
        ["mem_f", "grep MemFree /proc/meminfo | tr -s \" \" | cut -d \" \" -f2 | tr -d \"\\n\""],
        ["mem_t", "grep MemTotal /proc/meminfo | tr -s \" \" | cut -d \" \" -f2 | tr -d \"\\n\""],
        ["simno", "phytec-board-info --simno | tr -d \"\\n\""],
        ["compatible", "phytec-board-info --compatible | tr -d \"\\n\""],
        ["hwver", "phytec-board-info --machine-version | tr -d \"\\n\""],
        ["devtype", "phytec-board-info --machine | tr -d \"\\n\""],
        ["serial", "phytec-board-info --serial | tr -d \"\\n\""],
        ["remote_manager_version", "remotemanager -v | tr -d \"\\n\""],
        ["remotemanager_service_status", "systemctl is-active remotemanager.service | tr -d \"\\n\""],
        ["rauc-hawkbit-updater", "rauc-hawkbit-updater -v | tr -d \"\\n\""]
    ]'

if [ -f ${awsconfig} ]; then
        if ! [ -f ${awsconfig_zeus} ]; then
                cp ${awsconfig} ${awsconfig_zeus}
        fi
        jsontxt=$(cat ${awsconfig})
        [[ $(echo ${jsontxt} | jq 'isempty(.shadow_commands[])') = true ]] && jsontxt=$(echo ${jsontxt} | jq --argjson val "${shadowcommands}" '.shadow_commands += $val')
        echo ${jsontxt} | jq . > ${awsconfig}
fi

exit 0
