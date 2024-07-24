#!/bin/bash

# install_devopsfetch.sh

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install dependencies
apt-get update
apt-get install -y jq nginx docker.io net-tools finger

# Copy main script to /usr/local/bin
cp devopsfetch.sh /usr/local/bin/devopsfetch
chmod +x /usr/local/bin/devopsfetch

# Create systemd service file
cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch -p -d -n -u
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# reload systemd,enable & start the service
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

echo "DevOps Fetch has been installed and configured."
echo "You can now use 'devopsfetch' command or check the service status with 'systemctl status devopsfetch'"
