#!/bin/bash

# Global variables
DOMAIN_BASE="ad.team"        # Base domain format
DOMAIN_SUFFIX=".isucdc.com"  # Domain suffix
TEAM_RANGE=$(seq 1 39)       # Range of team numbers, can be modified
SMB_PORT=445                 # SMB port to check
OUTPUT_FILE="ad-targets.txt" # Output file

# Function to check SMB port and version
check_smb() {
    team_number=$1
    domain="${DOMAIN_BASE}${team_number}${DOMAIN_SUFFIX}"
    
    # Run nmap to check if SMB port is open and grab the SMB version
    nmap_output=$(nmap -p $SMB_PORT --script=smb-os-discovery $domain 2>/dev/null)

    # Check if the port is open
    if echo "$nmap_output" | grep -q "$SMB_PORT/tcp open"; then
        # Extract the IP address from the scan results
        ip_address=$(echo "$nmap_output" | grep -oP '(?<=Nmap scan report for )[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        
        if [ -n "$ip_address" ]; then
            # Output the result in the format "#,ip address:port"
            echo "$team_number,$ip_address:$SMB_PORT" >> $OUTPUT_FILE
        fi
    fi
}

# Main loop to iterate over all team numbers
for team_number in $TEAM_RANGE; do
    check_smb $team_number
done
