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

# Fetch the current blocklist from the server
fetch_blocklist() {
    curl -s -L -H "Authorization: Bearer $API_KEY" $SERVER_URL -o $TMP_FILE
    if [ $? -ne 0 ]; then
        log_message "Failed to fetch blocklist from server"
        exit 1
    fi
}

# Update Fail2ban with the new blocklist
update_fail2ban() {
    while IFS= read -r line; do
        ip=$(echo $line | grep -oP '(?<="ip":")[^"]*')
        if [ -n "$ip" ]; then
            fail2ban-client set f2b-network banip $ip
            if [ $? -eq 0 ]; then
                log_message "Successfully banned IP $ip"
            else
                log_message "Failed to ban IP $ip"
            fi
        fi
    done < $TMP_FILE
}

# Main script execution
log_message "Starting blocklist update"
fetch_blocklist
update_fail2ban
log_message "Blocklist update completed"