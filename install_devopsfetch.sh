#!/bin/bash

install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y nginx docker.io net-tools
}

configure_service() {
    sudo bash -c 'cat > /etc/systemd/system/sysinfo.service << EOF
[Unit]
Description=System Information Service

[Service]
ExecStart=/path/to/devopsfetch.sh -d
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
    sudo systemctl daemon-reload
    sudo systemctl enable sysinfo.service
    sudo systemctl start sysinfo.service
}

configure_log_rotation() {
    sudo bash -c 'cat > /etc/logrotate.d/sysinfo << EOF
/path/to/sysinfo.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root utmp
    sharedscripts
    postrotate
        systemctl restart sysinfo.service > /dev/null
    endscript
}
EOF'
}

install_all() {
    install_dependencies
    configure_service
    configure_log_rotation
}

install_all
