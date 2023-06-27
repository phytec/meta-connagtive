#!/bin/sh

set -eu

# VERSION TAG
version="v1.1.0"

cat<<EOF
-----------------------------------------------------------------------------------
                                IoT Suite Companion
-----------------------------------------------------------------------------------
This script holds a list of many useful commands related to managing your device.
It mainly works as a macro-library.
The commands, that are executed by this script will be echoed to the commandline.
EOF

CONFIG=/etc/aws/config/iot-companion.config
# Check for iot-companion.config file
if [ -f "${CONFIG}" ];then
        if [ -s "${CONFIG}" ];then
                printf "\nFile ${CONFIG} exists and not empty | Sourcing the file\n"
                . $CONFIG
        else
                printf "File ${CONFIG} exists but empty | Please check the file contents\n"
        fi
else
        printf "File ${CONFIG} not exists\n"
fi

## Hardware and BSP specific parameters
[ -s $AwsClientConfig ] && printf "$AwsClientConfig awsclient config file exists and not empty\n" || printf "$AwsClientConfig awsclient config file doesn't exist or is empty\n"

[ -s $AwsclientTimer ] && printf "$AwsclientTimer awsclient timer file exists and not empty\n" || printf "$AwsclientTimer awsclient timer file doesn't exist or is empty\n"

[ -s $RaucConfig ] && printf "$RaucConfig RAUC config file exists and not empty\n" || printf "$RaucConfig RAUC config file doesn't exist or is empty\n"

[ -s $JqOutput ] && printf "$JqOutput jq dump file exists and not empty\n" || printf "$JqOutput jq dump file doesn't exist or is empty\n"

if [ -s $AwsClientConfig.sha256 ]; then
        if ! sha256sum --check "$AwsClientConfig.sha256"; then
                printf "Stored hash for '$AwsClientConfig' does not match existing file, storing new hash\n"
                sha256sum "$AwsClientConfig" > "$AwsClientConfig.sha256"

                printf "Creating new jq dump file as new awsclient config file found\n"
                # Creating jq dump as new awsclient config file is found
                JqDump=$(jq -r 'to_entries[] | "\(.key)=\(.value)"' $AwsClientConfig > $JqOutput)
        else
                # hash file exists and matches existing file, do nothing
                # awsclient config file is not changed; using existing jq dump file
                if [ -s $JqOutput ]; then
                        printf "awsclient config file is not changed and using existing jq dump file\n"
                else
                        printf "jq dump file not found! Creating new jq dump file\n"
                        JqDump=$(jq -r 'to_entries[] | "\(.key)=\(.value)"' $AwsClientConfig > $JqOutput)
                        ## Ensuring if jq is successful
                        [ -s $JqOutput ] && printf "$JqOutput exists and not empty\n" || printf "$JqOutput doesn't exist or is empty\n"
                fi
        fi
else
        printf "No stored hash for '$AwsClientConfig', creating hash file\n"
        sha256sum "$AwsClientConfig" > "$AwsClientConfig.sha256"

        printf "\nCreating jq dump file for first time"
        # Creating jq dump file for first time
        JqDump=$(jq -r 'to_entries[] | "\(.key)=\(.value)"' $AwsClientConfig > $JqOutput)
fi

## Ideas for additional sections

# General
# versions      show Versions for all clients

# aws shadow            show Current Shadow
# aws onbaording        show Onboarding Status
# aws log show          show the log database
# aws log               use the loggig to cloud feature
# aws license           show license manager feature and configuration

# net                   network and connection related topics (selfcheck, IP, dns, ping)

# wan                   wan related informations and setting (ppp, ethernet, wifi)

# New Section "hw"      show all HW related information (OEM, Board, Revision, Serial, MAC, ..)
# New section "hsm"     show all security features and status of hsm/tpm/se

# phytec                show phytec tools (board-info, ... )

# developer             show how to install developer tools

# security              show security related infos (SSHD, Keys, hotp, )

# Configuration setup. Source jq dump file to retrieve configuration parameters
if . $JqOutput; then
        THING_NAME=$thing_name
        ENDPOINT=$endpoint

        ALLOW_LIST_FILE_DOWNLOAD=$maintenance_task_download_whitelist_path
        FILE_DOWNLOAD_TEMP_DIR=$maintenance_task_temp_download_dir

        ALLOW_LIST_COMMAND_EXCUTION=$maintenance_task_command_whitelist_path

        REMOTE_MANAGER_CONFIG_DIR=$remote_manager_config_dir
        REMOTE_MANAGER_CONFIG_FILE=$remote_manager_config_file
        REMOTE_MANAGER_CONFIG_FILE=$REMOTE_MANAGER_CONFIG_DIR""$REMOTE_MANAGER_CONFIG_FILE

        RAUC_HAWKBIT_CONFIG_DIR=$rauc_hawkbit_client_config_dir
        RAUC_HAWKBIT_CONFIG_FILE=$rauc_hawkbit_client_config_file
        RAUC_HAWKBIT_CONFIG_FILE=$RAUC_HAWKBIT_CONFIG_DIR""$RAUC_HAWKBIT_CONFIG_FILE

        RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION=$(awk -F "=" '/bundle_download_location/ {print $2}' $RAUC_HAWKBIT_CONFIG_FILE)

        SSH_PUB_KEY_DIR=$ssh_pub_key_dir
        SSH_PUB_KEY_FILE=$ssh_pub_key_file
        SSH_PUB_KEY_FILE=$SSH_PUB_KEY_DIR""$SSH_PUB_KEY_FILE
else
        printf "Couldn't find the jq dump file! Re-run the script to create new jq dump file. Please don't delete the jq_dump file manually.\n"
fi

script_dir=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
usage_header(){

cat<<EOF

Usage: $(basename "${0}") [-h] [-v] [aws OPTIONS] [update OPTIONS] [rauc OPTIONS] [tunnel OPTIONS] [support] [validate]
Available options:
-h, --help      Prints full help and exits
-v, --version   Print script VERSION
-p, --params    Print system parameters and configurations
Modules:
Enter     $(basename "${0}")  MODULE for module option
or        $(basename "${0}")  -h, --help for full help
$(basename "${0}") support          - Information and Links for IoT Suite and the support
$(basename "${0}") aws              - Controlling the awsclient of IoT Suite
$(basename "${0}") update           - Software Update Client
$(basename "${0}") rauc             - Local RAUC commands
$(basename "${0}") tunnel           - SSH Tunnel  Service
$(basename "${0}") validate         - Validate awsclient json file

EOF
}

usage_submodule_header(){
cat<<EOF

Usage: $(basename "${0}") [-h] [-v] [-p] [aws OPTIONS] [update OPTIONS] [rauc OPTIONS] [tunnel OPTIONS] [support] [validate]
EOF
}

print_parameters(){
usage_submodule_header

  echo "List of available configuration found in your system"
  echo " - AwsClientConfig      = $AwsClientConfig"
  echo " - AwsclientTimer       = $AwsclientTimer"
  echo " - RaucConfig           = $RaucConfig"

  echo "\n Values derived from your AWS Client config"
  echo " - THING_NAME                             = $THING_NAME"
  echo " - ENDPOINT                               = $ENDPOINT"
  echo " - ALLOW_LIST_FILE_DOWNLOAD               = $ALLOW_LIST_FILE_DOWNLOAD"
  echo " - ALLOW_LIST_COMMAND_EXCUTION            = $ALLOW_LIST_COMMAND_EXCUTION"
  echo " - FILE_DOWNLOAD_TEMP_DIR                 = $FILE_DOWNLOAD_TEMP_DIR"
  echo " - REMOTE_MANAGER_CONFIG_DIR              = $REMOTE_MANAGER_CONFIG_DIR"
  echo " - REMOTE_MANAGER_CONFIG_FILE             = $REMOTE_MANAGER_CONFIG_FILE"
  echo " - RAUC_HAWKBIT_CONFIG_DIR                = $RAUC_HAWKBIT_CONFIG_DIR"
  echo " - RAUC_HAWKBIT_CONFIG_FILE               = $RAUC_HAWKBIT_CONFIG_FILE"
  echo " - RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION  = $RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION"
  echo " - SSH_PUB_KEY_DIR                        = $SSH_PUB_KEY_DIR"
  echo " - SSH_PUB_KEY_FILE                       = $SSH_PUB_KEY_FILE"

}

usage_aws(){
usage_submodule_header
cat<<EOF
------------------------------------------------------------------------------------
MODULE:             $(basename "${0}") aws
                    awsclient - Client for health monitoring
------------------------------------------------------------------------------------
OPTIONS:
    start         - starts the service
    stop          - stops the service
    restart       - restarts the service
    status        - systemd status for the service

    timer         - shows the systemd timer for the awsclient
    timer-edit    - edit the systemd timer
    log           - show the latest log

    config        - show the config file $AwsClientConfig
    config-edit   - DANGEROUS: opens the config in vi
    file-allow    - content of allowlist for file transfer
    file-conf     - location/configuration for the allowlist
    file-edit     - edit existing allowlist for file transfer

    cmd-allow     - content of allowlist for remote commands
    cmd-conf      - location/configuration for the allowlist
    cmd-edit      - edit existing allowlist for remote commands

EOF
}

usage_update(){
usage_submodule_header
cat<<EOF

------------------------------------------------------------------------------------
MODULE:             $(basename "${0}") update
                    rauc-hawkbit-updater - Client that fetches the Software Updates
------------------------------------------------------------------------------------
OPTIONS:
    start         - starts the service
    stop          - stops the service
    restart       - restarts the service
    status        - systemd status for the service
    log           - show the latest log messages
    config        - show the config file $RAUC_HAWKBIT_CONFIG_FILE
    config-edit   - DANGEROUS: opens the config in vi

    repo          - download path download bundles
EOF
}

usage_rauc(){
usage_submodule_header
cat<<EOF

------------------------------------------------------------------------------------
MODULE:             $(basename "${0}") rauc
                    local RAUC operation
------------------------------------------------------------------------------------
OPTIONS:
    compat        - show system compatible string
    status        - show rauc system status
    detail        - show detailed rauc system status including bundle hashes
    switch        - activate the mirror system to be active after next boot
    noswitch      - activate the current system to be active after next boot
    markbad       - mark this slot as BAD - after next boot rauc might fallback
    marbad-other  - mark the mirror slot as BAD - after next boot rauc should boot current system
    markgood       - mark this slot as GOOD
    markgood-other - mark mirror slot as GOOD
    config        - show the config file $RaucConfig
    config-edit   - DANGEROUS: opens the config in vi
    config-reload - Restarts the rauc systemd service to reload the config (this is needed after compatible string change)

EOF
}

usage_tunnel(){
usage_submodule_header
cat<<EOF
------------------------------------------------------------------------------------
MODULE:             $(basename "${0}") tunnel
                    Remote Manager - SSH Tunnel through managed jump host
------------------------------------------------------------------------------------
OPTIONS:
    start         - starts the service   # Tunnel can only be actovated if configured in backend!
    stop          - stops the service
    restart       - restarts the service
    status        - systemd status for the service
    log           - show the latest log messages
    config        - show the config file $REMOTE_MANAGER_CONFIG_FILE
    config-edit   - DANGEROUS: opens the config in vi

    alive          - show active ssh connections
    keydir         - Key storage location
    pubkey         - show the public key

EOF
}

usage() {
  usage_header
  usage_aws
  echo
  usage_update
  echo
  usage_rauc
  echo
  usage_tunnel
  exit
}

print_support(){
cat<<EOF
IoT Device Suite
    Website              - https://iot-suite.io/
    Support              - mailto: support@iot-suite.io
    Sales                - mailto: sales@iot-suite.io
    Documentation        - http://doc.iot-suite.io (Redirect)
                         - https://osb-connagtive.atlassian.net/wiki/spaces/AIDSD/

    HowTos & Features    - https://osb-connagtive.atlassian.net/wiki/spaces/AIDSD/pages/1080033473/How+Tos+Features
    Technical Reference  - https://osb-connagtive.atlassian.net/wiki/spaces/AIDSD/pages/1080132047/Technical+Reference

    Terms & Conditions   - https://connagtive.com/agbs/?lang=en
    Coordinated Disclosure
                         - mailto: support@iot-suite.io Topic - Coordinated Disclosure
                           1) Please get in touch with us
                           2) Do not sensitive details in unencrpyted mails please
                           3) Emergency Contact:
                               Roland Marx
                               Mail:  roland.marx@osb-connagtive.com
                               Phone: +49 152 28511213
EOF
}

parse_params() {
  # default values of variables set from params
  while [ "$#" -ne 0 ]; do
    case "${1-}" in
    -h | --help) usage ;;
          -v | --version) echo $version ; exit 0 ;;
    -p | --params) print_parameters; exit 0 ;;

    ## AWSCLIENT
    aws)
      shift
        case "${1-}" in
        -h | --help) usage_aws ;;
        booted)
          echo "systemctl start awsclient"
          systemctl start awsclient;;
        start)
          echo "systemctl start awsclient"
          systemctl start awsclient;;
        stop)
          echo "systemctl stop awsclient"
          systemctl stop awsclient;;
        restart)
          echo "systemctl restart awsclient"
          systemctl restart awsclient;;
        status)
          echo "systemctl status awsclient"
          systemctl status awsclient;;
        timer)
          echo "systemctl list-timers awsclient.timer | cat"
          systemctl list-timers awsclient.timer | cat;;
        timer-edit)
          # awsclient Timer (example: OnUnitActiveSec=5m)
          echo "vi $AwsclientTimer"
          vi $AwsclientTimer;;
        log)
          echo "journalctl -f -u awsclient  #Latest entries shown in dynamic way"
          journalctl -f -u awsclient;;
        config)
          echo "cat $AwsClientConfig"
          cat $AwsClientConfig;;
        config-edit)
          echo "vi $AwsClientConfig"
          vi $AwsClientConfig;;
        # File Download
        file-allow)
          file=$ALLOW_LIST_FILE_DOWNLOAD
          echo "cat $file"
          cat $file ;;
        file-conf)
          file=$ALLOW_LIST_FILE_DOWNLOAD
          echo "$file";;
        #file-create)
        #  echo "#TODO# Please refer to the documentation to create a file"
        #  ;;
        file-edit)
          file=$ALLOW_LIST_FILE_DOWNLOAD
          echo "vi $file"
          vi $file ;;

        # Remote Command
        cmd-allow)
          file=$ALLOW_LIST_COMMAND_EXCUTION
          echo "cat $file"
          cat $file ;;
        cmd-conf)
          file=$ALLOW_LIST_COMMAND_EXCUTION
          echo "$file";;
        #cmd-create)
        #  echo "#TODO# Please refer to the documentation to create a file"
        #  ;;
        cmd-edit)
          file=$ALLOW_LIST_COMMAND_EXCUTION
          echo "vi $file"
          vi $file ;;
        ?*) printf '\nUnknown arguement for sub-command aws | Please refer to Usage\n' >&2; usage_aws exit 1 ;;
        *)
          usage_aws
          exit 1 ;;
        esac ;;

    ## RAUC-Hawkbit Update
    update)
      shift
        case "${1-}" in
        -h | --help) usage_update ;;
        start)
          echo "systemctl start rauc-hawkbit-updater"
          systemctl start rauc-hawkbit-updater;;
        stop)
          echo "systemctl stop rauc-hawkbit-updater"
          systemctl stop rauc-hawkbit-updater;;
        restart)
          echo "systemctl restart rauc-hawkbit-updater"
          systemctl restart rauc-hawkbit-updater;;
        status)
          echo "systemctl status rauc-hawkbit-updater"
          systemctl status rauc-hawkbit-updater;;
        log)
          echo "journalctl -f -u rauc-hawkbit-updater   #Latest entries shown in dynamic way"
          journalctl -f -u rauc-hawkbit-updater;;
        config)
          file=$RAUC_HAWKBIT_CONFIG_FILE
          echo "cat $file"
          cat $file ;;
        config-edit)
          file=$RAUC_HAWKBIT_CONFIG_FILE
          echo "vi $file"
          vi $file ;;
        repo)
          file=$(getRaucHawkbitRepo)
          echo $file
          ;;
        ?*) printf '\nUnknown arguement for sub-command update | Please refer to Usage\n' >&2; usage_update exit 1 ;;
        *)
          usage_update
          exit 1 ;;
        esac ;;
    ## RAUC-Lokal
    rauc)
      shift
        case "${1-}" in
        -h | --help) usage_rauc ;;
        compat)
          echo "cat $RaucConfig | grep compatible"
          cat $RaucConfig | grep compatible ;;
        status)
          echo "rauc status"
          rauc status;;
        detail)
          echo "rauc status --detailed"
          rauc status --detailed;;
        switch)
          echo "rauc status mark-active other"
          rauc status mark-active other;;
        noswitch)
          echo "rauc status mark-active booted"
          rauc status mark-active booted;;
        markbad)
          echo "rauc status mark-bad booted"
          rauc status mark-bad booted;;
        markbad-other)
          echo "rauc status mark-bad other"
          rauc status mark-bad other;;
        markgood)
          echo "rauc status mark-good booted"
          rauc status mark-good booted;;
        markgood-other)
          echo "rauc status mark-good other"
          rauc status mark-good other;;
        config)
          echo "cat $RaucConfig"
          cat $RaucConfig;;
        config-edit)
          echo "vi $RaucConfig"
          vi $RaucConfig;;
        config-reload)
          echo "systemctl restart rauc"
         systemctl restart rauc;;
        ?*) printf '\nUnknown arguement for sub-command rauc | Please refer to Usage\n' >&2; usage_rauc exit 1 ;;
        *)
          usage_rauc
          exit 1 ;;
        esac ;;

      ## Remote Manager - SSH Tunnel
    tunnel)
      shift
        case "${1-}" in
        -h | --help) usage_tunnel ;;
        start)
          echo "systemctl start remotemanager"
          systemctl start remotemanager;;
        stop)
          echo "systemctl stop remotemanager"
          systemctl stop remotemanager;;
        restart)
          echo "systemctl restart remotemanager"
          systemctl restart remotemanager;;
        status)
          echo "systemctl status remotemanager"
          systemctl status remotemanager;;
        log)
          echo "journalctl -f -u remotemanager   #Latest entries shown in dynamic way"
          journalctl -f -u remotemanager;;
        config)
          file=$REMOTE_MANAGER_CONFIG_FILE
          echo "cat $file"
          cat $file;;
        config-edit)
          file=$REMOTE_MANAGER_CONFIG_FILE
          echo "vi $file"
          vi $file;;
        alive)
          echo "netstat | grep ssh"
          netstat | grep ssh ;;
        keydir)
          dir=$SSH_PUB_KEY_DIR
          echo $dir
          echo
          ls -lh $dir;;
        pubkey)
          file=$SSH_PUB_KEY_FILE
          echo $file
          echo
          cat $file
          ;;
        ?*) printf '\nUnknown arguement for sub-command tunnel | Please refer to Usage\n' >&2; usage_tunnel exit 1 ;;
        *)
          usage_tunnel
          exit 1 ;;
        esac ;;
    validate)
        cat $AwsClientConfig | jq || printf >&2 "Invalid JSON syntax\n" ;;
    support)
      print_support ;;
    suite)
      print_support ;;
    ?*) printf '\nUnknown arguement | Please refer to Usage\n' >&2; usage_submodule_header exit 1 ;;
    *)
      usage_header
      exit 1 ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"

# script logic here
if [ $# -eq 0 ]; then
  usage_header
fi
