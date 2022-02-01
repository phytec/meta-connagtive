#!/usr/bin/env bash

#set -Eeuo pipefail
set -Eeo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT


cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

# VERSION TAG
version="v1.0.1"

## Hardware ond BSP specific parameters
AwsClientConfig="/mnt/config/aws/config/config.json"
AwsclientTimer="/etc/systemd/system/basic.target.wants/awsclient.timer"
RaucConfig="/etc/rauc/system.conf"


## Ideas for additional sectionso

# General 
# versions      show Versions for all clients

# aws shadow            show Current Shadow
# aws onbaording        show Onboarding Status
# aws log show 	        show the log database
# aws log               use the loggig to cloud feature
# aws license           show license manager feature and configuration

# net                   network and connection related topics (selfcheck, IP, dns, ping)

# wan                   wan related informations and setting (ppp, ethernet, wifi)

# New Section "hw"      show all HW related information (OEM, Board, Revision, Serial, MAC, ..)
# New section "hsm"     show all security features and status of hsm/tpm/se

# phytec		show phytec tools (board-info, ... )

# developer 		show how to install developer tools

# security		show security related infos (SSHD, Keys, hotp, )

############################################################################################################
#<<< CONFIGURATION PARSERS 

THING_NAME=$(jq -r .thing_name $AwsClientConfig)
ENDPOINT=$(jq -r .endpoint $AwsClientConfig)

ALLOW_LIST_FILE_DOWNLOAD=$(jq -r .maintenance_task_download_whitelist_path $AwsClientConfig)
FILE_DOWNLOAD_TEMP_DIR=$(jq -r .maintenance_task_temp_download_dir $AwsClientConfig)

ALLOW_LIST_COMMAND_EXCUTION=$(jq -r .maintenance_task_command_whitelist_path $AwsClientConfig)

REMOTE_MANAGER_CONFIG_DIR=$(jq -r .remote_manager_config_dir $AwsClientConfig)
REMOTE_MANAGER_CONFIG_FILE=$(jq -r .remote_manager_config_file $AwsClientConfig)
REMOTE_MANAGER_CONFIG_FILE=$REMOTE_MANAGER_CONFIG_DIR""$REMOTE_MANAGER_CONFIG_FILE

RAUC_HAWKBIT_CONFIG_DIR=$(jq -r .rauc_hawkbit_client_config_dir $AwsClientConfig)
RAUC_HAWKBIT_CONFIG_FILE=$(jq -r .rauc_hawkbit_client_config_file $AwsClientConfig)
RAUC_HAWKBIT_CONFIG_FILE=$RAUC_HAWKBIT_CONFIG_DIR""$RAUC_HAWKBIT_CONFIG_FILE

RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION=$(awk -F "=" '/bundle_download_location/ {print $2}' $RAUC_HAWKBIT_CONFIG_FILE)

SSH_PUB_KEY_DIR=$(jq -r .ssh_pub_key_dir $AwsClientConfig)
SSH_PUB_KEY_FILE=$(jq -r .ssh_pub_key_file $AwsClientConfig)
SSH_PUB_KEY_FILE=$SSH_PUB_KEY_DIR""$SSH_PUB_KEY_FILE

#<<< CONFIGURATION PARSERS 




#<<< usage 
#--------------------------------------------------------------------------------------------
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
usage_header(){

cat<<EOF
-----------------------------------------------------------------------------------------------------
  _____   _______    _____       _ _          _____                                  _             
 |_   _| |__   __|  / ____|     (_) |        / ____|                                (_)            
   | |  ___ | |    | (___  _   _ _| |_ ___  | |     ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
   | | / _ \| |     \___ \| | | | | __/ _ \ | |    / _ \|  _   _ \|  _ \ / _  |  _ \| |/ _ \|  _ \ 
  _| || (_) | |     ____) | |_| | | ||  __/ | |___| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
 |_____\___/|_|    |_____/ \__,_|_|\__\___|  \_____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                                                                  | |                              
                                                                  |_|                              
------------------------------------------------------- www.iot-suite.io by OSB connagtive GmbH -----
                             
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [aws OPTIONS] [update OPTIONS] [rauc OPTIONS] [tunnel OPTIONS] [support]

This script holds a list of many useful commands related to managing your device.
It mainly works as a macro-library. 
The commands, that are executed by this script will be echoed to the commandline.

Available options:

-h, --help      Prints full help and exits
-v, --version   Print script VERSION
-p, --params    Print system parameters and configurations


Modules:

Enter     $(basename "${BASH_SOURCE[0]}")  MODULE for module option
or        $(basename "${BASH_SOURCE[0]}")  -h, --help for full help 

$(basename "${BASH_SOURCE[0]}") support  - Information and Links for IoT Suite and the support
$(basename "${BASH_SOURCE[0]}") aws              - Controlling the awsclient of IoT Suite               
$(basename "${BASH_SOURCE[0]}") update           - Software Update Client 
$(basename "${BASH_SOURCE[0]}") rauc             - Local RAUC commands
$(basename "${BASH_SOURCE[0]}") tunnel           - SSH Tunnel  Service
                            
EOF
}

usage_submodule_header(){
cat<<EOF
-----------------------------------------------------------------------------------------------------
  _____   _______    _____       _ _          _____                                  _             
 |_   _| |__   __|  / ____|     (_) |        / ____|                                (_)            
   | |  ___ | |    | (___  _   _ _| |_ ___  | |     ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
   | | / _ \| |     \___ \| | | | | __/ _ \ | |    / _ \|  _   _ \|  _ \ / _  |  _ \| |/ _ \|  _ \ 
  _| || (_) | |     ____) | |_| | | ||  __/ | |___| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
 |_____\___/|_|    |_____/ \__,_|_|\__\___|  \_____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                                                                  | |                              
                                                                  |_|                              
------------------------------------------------------- www.iot-suite.io by OSB connagtive GmbH -----
                             
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-p] [aws OPTIONS] [update OPTIONS] [rauc OPTIONS] [tunnel OPTIONS] [support]

EOF
}

print_parameters(){

usage_submodule_header

cat<<EOF
  _____                              
 |  __ \\                             
 | |__) |_ _ _ __ __ _ _ __ ___  ___ 
 |  ___/ _  |  __/ _  |  _   _ \\/ __|
 | |  | (_| | | | (_| | | | | | \__ \\
 |_|   \__ _|_|  \__ _|_| |_| |_|___/                    
-------------------------------------------------------------------------------------------
EOF 
#https://patorjk.com/software/taag/#p=display&f=Big&t=Params%0A

  echo -e "List of available configuration found in your system"
  echo " - AwsClientConfig      = $AwsClientConfig"
  echo " - AwsclientTimer       = $AwsclientTimer"
  echo " - RaucConfig           = $RaucConfig"
  
  echo -e "\n Values derived from your AWS Client Config "  
  echo " THING_NAME = $THING_NAME"
  echo " ENDPOINT= $ENDPOINT"
  echo " ALLOW_LIST_FILE_DOWNLOAD= $ALLOW_LIST_FILE_DOWNLOAD"
  echo " ALLOW_LIST_COMMAND_EXCUTION= $ALLOW_LIST_COMMAND_EXCUTION"
  echo " FILE_DOWNLOAD_TEMP_DIR= $FILE_DOWNLOAD_TEMP_DIR"
  echo " REMOTE_MANAGER_CONFIG_DIR = $REMOTE_MANAGER_CONFIG_DIR"
  echo " REMOTE_MANAGER_CONFIG_FILE= $REMOTE_MANAGER_CONFIG_FILE"
  echo " RAUC_HAWKBIT_CONFIG_DIR= $RAUC_HAWKBIT_CONFIG_DIR"
  echo " RAUC_HAWKBIT_CONFIG_FILE = $RAUC_HAWKBIT_CONFIG_FILE"
  echo " RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION= $RAUC_HAWKBIT_BUNDLE_DOWNLOAD_LOCATION"
  echo " SSH_PUB_KEY_DIR= $SSH_PUB_KEY_DIR"
  echo " SSH_PUB_KEY_FILE = $SSH_PUB_KEY_FILE"
}

onboarding_status(){
usage_submodule_header
cat<<EOF
   ____        _                         _ _             
  / __ \      | |                       | (_)            
 | |  | |_ __ | |__   ___   __ _ _ __ __| |_ _ __   __ _ 
 | |  | | '_ \| '_ \ / _ \ / _` | '__/ _` | | '_ \ / _` |
 | |__| | | | | |_) | (_) | (_| | | | (_| | | | | | (_| |
  \____/|_| |_|_.__/ \___/ \__,_|_|  \__,_|_|_| |_|\__, |
                                                    __/ |
                                                   |___/ 
EOF

#ToDo
}


usage_aws(){
usage_submodule_header
cat<<EOF
   _____      _____ 
  / _ \ \ /\ / / __|
 | (_||\ V  V /\\__ \\
  \___| \_/\_/ |___/
------------------------------------------------------------------------------------ 
MODULE:             $(basename "${BASH_SOURCE[0]}") aws   
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
                  _       _       
                 | |     | |      
  _   _ _ __   __| | __ _| |_ ___ 
 | | | |  _ \ / _  |/ _  | __/ _ \\
 | |_| | |_) | (_| | (_| | ||  __/
  \__ _|  __/ \__ _|\__ _|\__\___|
       | |                        
       |_|                        
------------------------------------------------------------------------------------ 
MODULE:             $(basename "${BASH_SOURCE[0]}") update            
                    rauc-hawkbit-updater - Client that fetches the Software Updates 
------------------------------------------------------------------------------------ 
OPTIONS:
    start         - starts the service
    stop          - stops the service
    restart       - restarts the service
    status        - systemd status for the service

    log           - show the latest log messages

    config        - show the config file $RaucHawkbitConfig
    config-edit   - DANGEROUS: opens the config in vi
    
    repo          - download path download bundles

EOF
}

usage_rauc(){

usage_submodule_header
cat<<EOF
                       
  _ __ __ _ _   _  ___ 
 |  __/ _  | | | |/ __|
 | | | (_| | |_| | (__ 
 |_|  \__ _|\__ _|\___|                               
------------------------------------------------------------------------------------ 
MODULE:             $(basename "${BASH_SOURCE[0]}") rauc            
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
  _                          _ 
 | |                        | |
 | |_ _   _ _ __  _ __   ___| |
 | __| | | | '_ \| '_ \ / _ \ |
 | |_| |_| | | | | | | |  __/ |
  \__|\__,_|_| |_|_| |_|\___|_|
------------------------------------------------------------------------------------ 
MODULE:             $(basename "${BASH_SOURCE[0]}") tunnel            
                    Remote Manager - SSH Tunnel through managed jump host
------------------------------------------------------------------------------------ 
OPTIONS:
    start         - starts the service   # Tunnel can only be actovated if configured in backend!
    stop          - stops the service
    restart       - restarts the service
    status        - systemd status for the service

    log           - show the latest log messages

    config        - show the config file $RemoteManagerConfig
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

print_support(){
cat<<EOF
IoT Suite             # local RAUC operation  
    Website              - https://www.osb-connagtive.com
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
  while :; do
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
          echo "journalctl -n 30 -r  -u awsclient   #Last (-r) 30 lines (-n 30)"
          journalctl -n 30 -r  -u awsclient;;
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
        -?*) die "Unknown option: $1" ;;
        *) usage_aws break ;;
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
          echo "journalctl -n 30 -r  -u rauc-hawkbit-updater   #Last (-r) 30 lines (-n 30)"
          journalctl -n 30 -r  -u rauc-hawkbit-updater;;
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
          
        -?*) die "Unknown option: $1" ;;
        *) usage_update break ;;
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
        -?*) die "Unknown option: $1" ;;
        *) usage_rauc break ;;
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
          echo "journalctl -n 30 -r  -u remotemanager   #Last (-r) 30 lines (-n 30)"
          journalctl -n 30 -r  -u remotemanager;;
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
          
        -?*) die "Unknown option: $1" ;;
        *) usage_tunnel break ;;
        esac ;;
    support)
      print_support ;;
    suite)
      print_support ;; 
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")
  # check required params and arguments
  #[[ ${#args[@]} -eq 0 ]] && usage_header

  return 0
}

parse_params "$@"
setup_colors

# script logic here
if [ $# -eq 0 ]; then
  usage_header
fi
