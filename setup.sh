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

check_old_install(){
    if [[ -d "${root_install_path}" ]]; then
        old_install=true;
    fi
}

migration_old_mcsmanager(){
    print_log "ERROR" "Not implemented yet";
    return 1;
}

install_node() {
    print_log "INFO" "Installing Node.js ${node_version} ...";
    
    # Download Node.js
    if ${DEBUG}; then
        wget "${node_download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -v -O "${tmp_path}/node.tar.gz";
        wget "${node_hash_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -v -O "${tmp_path}/node.sha256";
    else
        wget "${node_download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -O"${tmp_path}/node.tar.gz";
        wget "${node_hash_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -O "${tmp_path}/node.sha256";
    fi
    
    # Check Node.js integrity
    local offical_hash
    local file_hash
    offical_hash=$(grep "node-${node_version}-linux-${arch}.tar.gz" "${tmp_path}/node.sha256" | awk '{ print $1 }');
    file_hash=$(sha256sum "${tmp_path}/node.tar.gz" | awk '{ print $1 }');
    if [[ "${offical_hash}" != "${file_hash}" ]]; then
        print_log "ERROR" "Node.js checksum failure!"
        print_log "ERROR" "Expected: ${offical_hash}";
        print_log "ERROR" "Actual: ${file_hash}";
        return 1;
    fi
    
    # Install Node.js
    if ${DEBUG}; then
        tar -zxvf "${tmp_path}/node.tar.gz" -C "${node_install_path}";
    else
        tar -zxf "${tmp_path}/node.tar.gz" -C "${node_install_path}";
    fi
    
    # Set permissions
    chmod +x "${node_install_path}/bin/node";
    chmod +x "${node_install_path}/bin/npm";
    
    # Check Node.js installation
    if [[ -f "${node_install_path}"/bin/node ]] && [[ "$("${node_install_path}"/bin/node -v)" == "${node_version}" ]]; then
        print_log "INFO" "Node.js ${node_version} installed successfully!";
    else
        print_log "ERROR" "Node.js installation failed!";
        return 1;
    fi
    
    return 0;
}

install_mcsmanager() {
    print_log "INFO" "Installing MCSManager ...";
    
    # Download MCSManager
    if ${DEBUG}; then
        wget "${mcsmanager_download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -v -O "${tmp_path}/mcsmanager.tar.gz";
        wget "${mcsmanager_hash_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -v -O "${tmp_path}/mcsmanager.sha256";
    else
        wget "${mcsmanager_download_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -O "${tmp_path}/mcsmanager.tar.gz";
        wget "${mcsmanager_hash_url}" -q --progress=bar:force -c --retry-connrefused -t 5 -O "${tmp_path}/mcsmanager.sha256";
    fi
    
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
    mv -f "${tmp_path}/mcsmanger/web" "${web_install_path}";
    mv -f "${tmp_path}/mcsmanger/daemon" "${daemon_install_path}";
    
    # Install dependencies
    install_npm_packages "${web_install_path}"
    install_npm_packages "${daemon_install_path}"
    
    # Set permissions
    chmod -R 755 /opt/mcsmanager/
    
    # Register MCSManager services
    create_service_file "mcsm-web.service" "MCSManager-Web" "/opt/mcsmanager/web"
    create_service_file "mcsm-daemon.service" "MCSManager-Daemon" "/opt/mcsmanager/daemon"
    systemctl daemon-reload
    
    return 0;
}

install_npm_packages() {
    local install_path=$1
    if cd "${install_path}"; then
        /usr/bin/env "${node_install_path}"/bin/node "${node_install_path}"/bin/npm install --production --no-fund --no-audit >npm_install_log
    else
        print_log "ERROR" "Failed to change directory to ${install_path}";
        return 1;
    fi
    
    return 0;
}

create_service_file() {
    local file_name=$1
    local service_name=$2
    local working_directory=$3
    # shellcheck disable=SC2250,SC2154
    cat << EOF > "/etc/systemd/system/${file_name}"
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
    
    return 0;
}
