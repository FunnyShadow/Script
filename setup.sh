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
old_install=false;
network=false;
public_ip=$(curl -s http://ipecho.net/plain);
private_ip=$(hostname -i | awk '{print $1}');
arch=$(uname -m);


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

# Migratior (WIP)
function migration_old_mcsmanager(){
    print_log "ERROR" "Not implemented yet";
    return 1;
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

# System check (WIP)
function check_system(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

# Network check (WIP)
function check_network(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

# Dependency check (WIP)
function check_deps(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

# Old installation check
function check_old_install(){
    if [[ -d "${root_install_path}" ]]; then
        old_install=true;
    fi
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
    
    # Set permissions
    sudo chmod -R 755 "${web_install_path}";
    sudo chmod -R 755 "${daemon_install_path}";
    
    # Register MCSManager services
    sudo bash -c "$(declare -f create_service_file); create_service_file 'mcsm-web.service' 'MCSManager Web' '${web_install_path}'";
    sudo bash -c "$(declare -f create_service_file); create_service_file 'mcsm-daemon.service' 'MCSManager Daemon' '${daemon_install_path}'";
    sudo systemctl daemon-reload;
    
    return 0;
}

### Main
print_log "DEBUG" "Public IP: ${public_ip}";
print_log "DEBUG" "Private IP: ${private_ip}";
print_log "DEBUG" "Architecture: ${arch}";

print_log "INFO" "+----------------------------------------------------------------------";
print_log "INFO" "| MCSManager Installer";
print_log "INFO" "+----------------------------------------------------------------------";

# still in development

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