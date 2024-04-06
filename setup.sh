#!/bin/bash
# shellcheck disable=SC2034,SC2312
# shellcheck enable=all
###########################
### Variables
## Features
DEBUG=false;

## Paths
root_install_path="/opt/mcsmanager";
node_install_path="${root_install_path}/node/${node_version}";
web_install_path="${root_install_path}/web";
daemon_install_path="${root_install_path}/daemon";
tmp_path="/tmp/mcsmanager";

## URLs
mcsmanager_download_url="http://oss.duzuii.com/d/MCSManager/MCSManager/MCSManager-v10-linux.tar.gz";
mcsmanager_hash_url="";
node_download_url="https://nodejs.org/dist/${node_version}/node-${node_version}-linux-${arch}.tar.gz";
node_hash_url="https://nodejs.org/dist/${node_version}/SHASUMS256.txt";

## Versions
node_version="v16.20.2";

## Script
# DO NOT MODIFY
old_install=false
network=false
public_ip=$(curl -s http://ipecho.net/plain)
private_ip=$(hostname -i | awk '{print $1}')


### Functions
## Utils
# Logger
print_log() {
    local level=$1;
    local message=$2;
    
    case "$1" in
        "DEBUG")
            if ${DEBUG}; then
                printf "\033[90m[ \033[96mDEBUG\033[0m \033[90m] \033[96m%s\033[0m\n" "$2";
            fi
            return 0;
        ;;
        "INFO")
            printf "\033[90m[ \033[92mINFO\033[0m \033[90m] \033[92m%s\033[0m\n" "$2";
            return 0;
        ;;
        "WARN")
            printf "\033[90m[ \033[93mWARN\033[0m \033[90m] \033[93m%s\033[0m\n" "$2";
            return 0;
        ;;
        "ERROR")
            printf "\033[90m[ \033[91mERROR\033[0m \033[90m] \033[91m%\033[0m\n" "$2";
            return 0;
        ;;
        "FATAL")
            printf "\033[90m[ \033[41m\033[37mFATAL\033[0m \033[90m] \033[41m\033[37m%s\033[0m\n" "$2";
            return 0;
        ;;
        *)
            printf "\033[90m[ \033[41m\033[37mFATAL\033[0m \033[90m] \033[41m\033[37m%s\033[0m\n" "Unable to recognize log level! Please check the script!"
            exit 1;
    esac
}

error_handler() {
    local err_line=$1;
    print_log "FATAL" "An unexpected error occurred!";
    print_log "FATAL" "Error line: ${err_line}";
    exit 1;
}

trap 'error_handler "$LINENO"' ERR;

check_arch(){
    case "${arch}" in
        x86_64)
            arch=x64;
        ;;
        aarch64)
            arch=arm64;
        ;;
        arm)
            arch=armv7l;
        ;;
        ppc64le)
            arch=ppc64le;
        ;;
        s390x)
            arch=s390x;
        ;;
        *)
            print_log "ERROR" "Unsupported architecture!";
            print_log "ERROR" "Please try to install manually: https://github.com/MCSManager/MCSManager#linux";
            return 1;
        ;;
    esac
    return 0;
}

check_system(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

check_network(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

check_deps(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

check_root(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}
migration_old_mcsmanager(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

[Service]
WorkingDirectory=/opt/mcsmanager/web
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/mcsm-web.service

  if [ -e "/etc/systemd/system/mcsm-web.service" ]; then
    sudo systemctl daemon-reload
    sudo systemctl enable mcsm-daemon.service --now
    sudo systemctl enable mcsm-web.service --now
    echo_green "Registered!"
  else
    printf "\n\n"
    echo_red "The MCSManager was successfully installed to \"/opt/mcsmanager\"."
    echo_red "But register to the \"systemctl\" failed!\nPlease use the \"root\" account to re-run the script!"
    exit
  fi

  sleep 2

  printf "\n\n\n\n"

  echo_yellow "=================================================================="
  echo_green "Installation is complete! Welcome to the MCSManager!!!"
  echo_yellow " "
  echo_cyan_n "HTTP Web Service:        "
  echo_yellow "http://<Your IP>:23333  (Browser)"
  echo_cyan_n "Daemon Address:          "
  echo_yellow "ws://<Your IP>:24444    (Cluster)"
  echo_red "You must expose ports 23333 and 24444 to use the service properly on the Internet."
  echo_yellow " "
  echo_cyan "Usage:"
  echo_cyan "systemctl start mcsm-{daemon,web}.service"
  echo_cyan "systemctl stop mcsm-{daemon,web}.service"
  echo_cyan "systemctl restart mcsm-{daemon,web}.service"
  echo_yellow " "
  echo_green "Official Document: https://docs.mcsmanager.com/"
  echo_yellow "=================================================================="
}

# Environmental inspection
if [[ "$arch" == x86_64 ]]; then
  arch=x64
  #echo "[-] x64 architecture detected"
elif [[ $arch == aarch64 ]]; then
  arch=arm64
  #echo "[-] 64-bit ARM architecture detected"
elif [[ $arch == arm ]]; then
  arch=armv7l
  #echo "[-] 32-bit ARM architecture detected"
elif [[ $arch == ppc64le ]]; then
  arch=ppc64le
  #echo "[-] IBM POWER architecture detected"
elif [[ $arch == s390x ]]; then
  arch=s390x
  #echo "[-] IBM LinuxONE architecture detected"
else
  Red_Error "[x] Sorry, this architecture is not supported yet!"
  Red_Error "[x] Please try to install manually: https://github.com/MCSManager/MCSManager#linux"
  exit
fi

# Define the variable Node installation directory
node_install_path="/opt/node-$node-linux-$arch"

# Check network connection
echo_cyan "[-] Architecture: $arch"

# Install related software
echo_cyan_n "[+] Installing dependent software(git,tar)... "
if [[ -x "$(command -v yum)" ]]; then
  sudo yum install -y git tar >error
elif [[ -x "$(command -v apt-get)" ]]; then
  sudo apt-get install -y git tar >error
elif [[ -x "$(command -v pacman)" ]]; then
  sudo pacman -Syu --noconfirm git tar >error
elif [[ -x "$(command -v zypper)" ]]; then
  sudo zypper --non-interactive install git tar >error
fi

# Determine whether the relevant software is installed successfully
if [[ -x "$(command -v git)" && -x "$(command -v tar)" ]]; then
  echo_green "Success"
else
  echo_red "Failed"
  echo "$error"
  Red_Error "[x] Related software installation failed, please install git and tar packages manually!"
  exit
fi

# Install the Node environment
Install_Node

# Install MCSManager
Install_MCSManager

# Create MCSManager background service
Create_Service
