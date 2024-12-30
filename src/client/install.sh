#! /bin/bash

# Check if fail2ban is installed
if ! command -v fail2ban-client 2>&1; then
    echo "Fail2ban is not installed. Please install it first."
    exit 1
fi

# Create the directory for f2b-network
INSTALL_DIR="/etc/fail2ban/f2b-network"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating directory $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Copy the client files to the installation directory
echo "Copying client files to $INSTALL_DIR"
cp -r "$(dirname "$0")"/* "$INSTALL_DIR"

# Move the f2b-network.local file to /etc/fail2ban/jail.d
echo "Moving f2b-network.local to /etc/fail2ban/jail.d"
mv "$INSTALL_DIR/f2b-network.local" /etc/fail2ban/jail.d

# Move the send_ip.conf file to /etc/fail2ban/action.d
echo "Moving send_ip.conf to /etc/fail2ban/action.d"
mv "$INSTALL_DIR/send_ip.conf" /etc/fail2ban/action.d

# Changing the permissions of the send_ip.sh and update_blocklist.sh file
echo "Changing permissions of send_ip.sh and update_blocklist.sh"
chmod u+x "$INSTALL_DIR/send_ip.sh"
chmod u+x "$INSTALL_DIR/update_blocklist.sh"

# Check if f2b-network.conf exists in /etc/fail2ban/f2b-network
if [ ! -f "/etc/fail2ban/f2b-network/f2b-network.conf" ]; then
    echo "f2b-network.conf not found. Please download it from the repository."
fi

# Restart fail2ban if it is running
if systemctl is-active --quiet fail2ban; then
    echo "Restarting fail2ban"
    systemctl restart fail2ban
fi

echo "Installation complete. Please configure f2b-network.conf and restart fail2ban."