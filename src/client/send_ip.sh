#!/bin/bash

# Load configuration from f2b-network.conf
CONFIG_FILE="$(dirname "$0")/f2b-network.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"
LOG_FILE="$(pwd)/$LOG_FILE"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Validate IP address format
is_valid_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Main script
IP="$1"

if [ -z "$IP" ]; then
    log_message "No IP address provided"
    exit 1
fi

if ! is_valid_ip "$IP"; then
    log_message "Invalid IP address format: $IP"
    exit 1
fi

# Send IP to server
response=$(curl -s -w "%{http_code}" -o /dev/null -L -X POST -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d "{\"ip\":\"$IP\"}" $SERVER_URL)

if [ "$response" -eq 201 ]; then
    log_message "Successfully added IP $IP to blocklist"
elif [ "$response" -eq 200 ]; then
    log_message "IP $IP is already in blocklist"
    exit 0
else
    log_message "Failed to add IP $IP to blocklist, response code: $response"
    exit 1
fi

bash update_blacklist.sh