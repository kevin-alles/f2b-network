#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Python is installed
if ! command_exists python3; then
    echo "Python3 is not installed. Please install Python3 and try again."
    exit 1
fi

# Create the directory /opt/f2b-network/
INSTALL_DIR="/opt/f2b-network"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating the installation directory $INSTALL_DIR and setting permissions..."
    mkdir -p "$INSTALL_DIR"
    chown "$USER":"$USER" "$INSTALL_DIR"
fi

# Copy server files to the installation directory
echo "Copying server files to the installation directory..."
cp -r "$(dirname "$0")"/* "$INSTALL_DIR"

# Navigate to the installation directory
cd "$INSTALL_DIR"

# Create a Python virtual environment
echo "Creating a Python virtual environment..."
python3 -m venv venv

# Activate the virtual environment
echo "Activating the Python virtual environment..."
source venv/bin/activate

# Install required Python packages
echo "Installing required Python packages..."
pip install -r requirements.txt

# Set up the service if root
if [ "$EUID" -eq 0 ]; then
    echo "Setting up the service..."
    cp f2b-network.service /etc/systemd/system/
    systemctl enable f2b-network
    systemctl start f2b-network
else
    echo "The service has not been set up because you are not root."
    echo "Please run the following commands as root to set up the service:"
    echo "cp f2b-network.service /etc/systemd/system/"
    echo "systemctl enable f2b-network"
    echo "systemctl start f2b-network"
fi

echo "Installation completed successfully."