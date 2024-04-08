#!/bin/bash
# shellcheck disable=SC2034,SC2312,SC1091
#########################################
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
update=false;

### Functions
## Utils
# Logger
function print_log() {
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

# Error handler
function error_handler() {
    local err_line=$1;
    print_log "FATAL" "An unexpected error occurred!";
    print_log "DEBUG" "Error line: ${err_line}";
    exit 1;
}

trap 'error_handler "$LINENO"' ERR;

# Cleaner
function cleaner(){
    # Check if the installation method is docker
    print_log "INFO" "Checking for Docker installation...";
    if [[ -f "${root_install_path}/docker-compose.yml" ]]; then
        print_log "WARN" "Docker installation detected!";
        print_log "WARN" "Please use the Docker update method provided in the official documentation to update MCSManager!";
        print_log "WARN" "Official Documentation: https://docs.mcsmanager.com/";
        return 1;
    fi
    
    # Stop MCSManager service
    print_log "INFO" "Stop the MCSManager service...";
    sudo systemctl disable --now mcsm-{daemon,web}.service;
    migration true;
    
    # Cleanup old MCSManager
    print_log "INFO" "Cleaning up old MCSManager...";
    sudo rm -rf "${root_install_path}";
    sudo rm -f /etc/systemd/system/mcsm-{daemon,web}.service;
    return 0;
}

# Migration
function migration(){
    local is_backup;
    is_backup="$1";
    print_log "DEBUG" "Backup: ${is_backup}";
    if ${is_backup}; then
        print_log "INFO" "Backing up MCSManager data...";
        sudo mv -f "${root_install_path}/web/data" "${tmp_path}/data/web";
        sudo mv -f "${root_install_path}/daemon/data" "${tmp_path}/data/daemon";
    else
        print_log "INFO" "Recovering MCSManager data..."
        sudo mv -f "${tmp_path}/data/web" "${root_install_path}/web/data";
        sudo mv -f "${tmp_path}/data/daemon" "${root_install_path}/daemon/data";
    fi
    return 0;
}


# Node dependency installer
function install_npm_packages() {
    local install_path=$1
    print_log "DEBUG" "Installing NPM packages...";
    print_log "DEBUG" "Install path: ${install_path}";
    if cd "${install_path}"; then
        /usr/bin/env "${node_install_path}"/bin/node "${node_install_path}"/bin/npm install --production --no-fund --no-audit > npm_install_log
    else
        print_log "ERROR" "Failed to change directory to ${install_path}";
        return 1;
    fi
    
    return 0;
}

# Service file creator
function create_service_file() {
    local file_name=$1;
    local service_name=$2;
    local working_directory=$3;
    print_log "DEBUG" "Creating service file...";
    print_log "DEBUG" "File name: ${file_name}";
    print_log "DEBUG" "Service name: ${service_name}";
    print_log "DEBUG" "Working directory: ${working_directory}";
    # shellcheck disable=SC2250,SC2154
    if ${DEBUG}; then
        cat << EOF | tee "/etc/systemd/system/${file_name}";
[Unit]
Description=${service_name}

[Service]
WorkingDirectory=${working_directory}
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment="PATH=${PATH}"

[Install]
WantedBy=multi-user.target
EOF
    else
        cat << EOF > "/etc/systemd/system/${file_name}";
[Unit]
Description=${service_name}

[Service]
WorkingDirectory=${working_directory}
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment="PATH=${PATH}"

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    return 0;
}

# File downloader
function download_file(){
    local download_url=$1;
    local file_name=$2;
    print_log "DEBUG" "Downloading file...";
    print_log "DEBUG" "Download URL: ${download_url}";
    print_log "DEBUG" "File name: ${file_name}";
    print_log "DEBUG" "File saved path: ${tmp_path}/${file_name}";
    if ${DEBUG}; then
        wget "${download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -v -O "${tmp_path}/${file_name}";
    else
        wget "${download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -O"${tmp_path}/${file_name}";
    fi
    
    return 0;
}

## Checks
# Arch check
function check_arch(){
    local arch
    arch=$(uname -m);
    print_log "DEBUG" "Original architecture: ${arch}";
    case "${arch}" in
        "x86_64")
            arch="x64";
        ;;
        "aarch64")
            arch="arm64";
        ;;
        "arm")
            arch="armv7l";
        ;;
        "ppc64le")
            arch="ppc64le";
        ;;
        "s390x")
            arch="s390x";
        ;;
        *)
            print_log "ERROR" "Unsupported architecture!";
            print_log "ERROR" "Please try to install manually: https://github.com/MCSManager/MCSManager#linux";
            return 1;
        ;;
    esac
    print_log "DEBUG" "Converted architecture: ${arch}"
    return 0;
}

# System check
function check_system(){
    local os
    os=$(uname)
    print_log "DEBUG" "System Type: ${os}";
    if [[ "${os}" == "Linux" ]]; then
        # shellcheck source=/etc/os-release
        . /etc/os-release;
        print_log "DEBUG" "System ID: ${ID}";
        print_log "DEBUG" "System Name: ${PRETTY_NAME}";
        if [[ ${ID} != "ubuntu" ]] && [[ ${ID} != "debian" ]] && [[ ${ID} != "centos" ]] && [[ ${ID} != "fedora" ]] && [[ ${ID} != "rocky" ]]; then
            print_log "ERROR" "Unsupported system!";
            print_log "ERROR" "Please try to install manually:https://github.com/MCSManager/MCSManager#linux";
            return 1;
        fi
    else
        print_log "ERROR" "Unsupported system!";
        print_log "ERROR" "Please try to install manually:https://github.com/MCSManager/MCSManager#linux";
        return 1;
    fi
    return 0;
}

# Dependency check and installation
function check_deps(){
    print_log "DEBUG" "System ID: ${ID}";
    print_log "DEBUG" "System Name: ${PRETTY_NAME}";
    case "${ID}" in
        "ubuntu" | "debian")
            sudo apt-get update
            sudo apt-get install git tar -y
        ;;
        "centos" | "fedora" | "rocky")
            sudo yum update
            sudo yum install git tar -y
        ;;
        *)
            print_log "ERROR" "Unsupported system!";
            print_log "ERROR" "Please try to install manually:https://github.com/MCSManager/MCSManager#linux";
            return 1;
        ;;
    esac
}

## Install
# Node.js installer
function install_node() {
    print_log "INFO" "Installing Node.js ${node_version} ...";
    
    # Download Node.js
    download_file "${node_download_url}" "node.tar.gz";
    download_file "${node_hash_url}" "node.sha256";
    
    # Check Node.js integrity
    local offical_hash
    local file_hash
    offical_hash=$(grep "node-${node_version}-linux-${arch}.tar.gz" "${tmp_path}/node.sha256" | awk '{ print $1 }');
    file_hash=$(sha256sum "${tmp_path}/node.tar.gz" | awk '{ print $1 }');
    if [[ "${offical_hash}" != "${file_hash}" ]]; then
        print_log "ERROR" "Node.js checksum failure!";
        print_log "ERROR" "Expected: ${offical_hash}";
        print_log "ERROR" "Actual: ${file_hash}";
        return 1;
    fi
    
    # Install Node.js
    if ${DEBUG}; then
        sudo tar -zxvf "${tmp_path}/node.tar.gz" -C "${node_install_path}";
    else
        sudo tar -zxf "${tmp_path}/node.tar.gz" -C "${node_install_path}";
    fi
    
    # Set permissions
    sudo chown -R 1000:1000 "${node_install_path}";
    sudo chmod -R 755 "${node_install_path}";
    
    # Check Node.js installation
    print_log "DEBUG" Node.js version: "$("${node_install_path}/bin/node" -v)"
    print_log "DEBUG" NPM version: "$("${node_install_path}/bin/node ${node_install_path}/bin/npm" -v)"
    if [[ -f "${node_install_path}"/bin/node ]] && [[ "$("${node_install_path}/bin/node" -v)" == "${node_version}" ]]; then
        print_log "INFO" "Node.js ${node_version} installed successfully!";
    else
        print_log "ERROR" "Node.js installation failed!";
        return 1;
    fi
    
    return 0;
}

# MCSManager installer
function install_mcsmanager() {
    print_log "INFO" "Installing MCSManager ...";
    
    # Download MCSManager
    download_file "${mcsmanager_download_url}" "mcsmanager.tar.gz";
    download_file "${mcsmanager_hash_url}" "mcsmanager.sha256";
    
    # Check MCSManager integrity
    local offical_hash
    local file_hash
    offical_hash=$(cat "${tmp_path}/mcsmanager.sha256");
    file_hash=$(sha256sum "${tmp_path}/mcsmanager.tar.gz" | awk '{ print $1 }');
    if [[ "${offical_hash}" != "${file_hash}" ]]; then
        print_log "ERROR" "MCSManager checksum failure!"
        print_log "ERROR" "Expected: ${offical_hash}";
        print_log "ERROR" "Actual: ${file_hash}";
        return 1;
    fi
    
    # Install MCSManager
    if ${DEBUG}; then
        tar -zxvf "${tmp_path}/mcsmanager.tar.gz" -C "${tmp_path}/mcsmanger";
    else
        tar -zxf "${tmp_path}/mcsmanager.tar.gz" -C "${tmp_path}/mcsmanger";
    fi
    sudo mv -f "${tmp_path}/mcsmanger/web" "${web_install_path}";
    sudo mv -f "${tmp_path}/mcsmanger/daemon" "${daemon_install_path}";
    
    # Install dependencies
    install_npm_packages "${web_install_path}";
    install_npm_packages "${daemon_install_path}";
    
    # Add user
    print_log "INFO" "Adding user..."
    sudo useradd -r -s /bin/false -U mcsmanager;
    
    # Set permissions
    print_log "INFO" "Setting permissions..."
    sudo chown -R mcsmanager:mcsmanager "${web_install_path}";
    sudo chown -R mcsmanager:mcsmanager "${daemon_install_path}";
    sudo chmod -R 755 "${web_install_path}";
    sudo chmod -R 755 "${daemon_install_path}";
    
    # Register MCSManager services
    sudo bash -c "$(declare -f create_service_file); create_service_file 'mcsm-web.service' 'MCSManager Web' '${web_install_path}'";
    sudo bash -c "$(declare -f create_service_file); create_service_file 'mcsm-daemon.service' 'MCSManager Daemon' '${daemon_install_path}'";
    sudo systemctl daemon-reload;
    
    return 0;
}

## Main
function main(){
    local public_ip
    local private_ip
    public_ip=$(curl -s http://ipecho.net/plain);
    private_ip=$(hostname -i | awk '{print $1}');
    print_log "DEBUG" "Public IP: ${public_ip}";
    
    print_log "INFO" "+----------------------------------------------------------------------";
    print_log "INFO" "| MCSManager Installer";
    print_log "INFO" "+----------------------------------------------------------------------";
    
    # Check if the installation directory exists
    if [[ -d ${root_install_path} ]]; then
        update=true;
        cleaner;
    fi
    
    # Basic checks
    check_arch;
    check_system;
    check_deps;
    
    # Install
    install_node;
    install_mcsmanager;
    
    if ${update}; then
        migration
        sudo systemctl enable --now mcsm-{web,daemon}.service
    fi
    
    print_log "INFO" "+----------------------------------------------------------------------";
    print_log "INFO" "| Installation is complete! Welcome to the MCSManager!!!";
    print_log "INFO" "|";
    print_log "INFO" "| HTTP Web Service: http://${public_ip}:23333 or http://${private_ip}:23333";
    print_log "INFO" "| Daemon Address: ws://${public_ip}:24444 or ws://${private_ip}:24444";
    print_log "INFO" "| You must expose ports 23333 and 24444 to use the service properly on the Internet.";
    print_log "INFO" "|";
    print_log "INFO" "| Usage:";
    print_log "INFO" "| systemctl start mcsm-{daemon,web}.service";
    print_log "INFO" "| systemctl stop mcsm-{daemon,web}.service";
    print_log "INFO" "| systemctl restart mcsm-{daemon,web}.service";
    print_log "INFO" "|";
    print_log "INFO" "| Official Document: https://docs.mcsmanager.com/";
    print_log "INFO" "+----------------------------------------------------------------------";
}

### Entrypoint
main