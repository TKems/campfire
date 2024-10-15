#!/bin/bash

# Global variables
start_team=1  # Starting team number (adjustable)
end_team=39   # Ending team number (adjustable)
hosts=("db" "camera" "guard", "ad")  # Array of host types
output_file="ssh-targets.txt"  # Output file
ports=(22 2222 8022 2022 20222 20022)  # Common SSH ports

# Clear the output file if it exists
> $output_file

# Function to scan hosts for SSH ports and check if SSH service is running
scan_host() {
    local host=$1
    local team_number=$2
    echo "Scanning $host..."

    # Use nmap to scan the specified SSH ports and detect service versions
    nmap_output=$(nmap -p$(IFS=,; echo "${ports[*]}") -sV $host --open | grep "open")

    # If the host has open ports, process the output
    if [ ! -z "$nmap_output" ]; then
        echo "$nmap_output" | while read -r line; do
            ip_address=$(echo "$line" | grep -oP '(\d{1,3}\.){3}\d{1,3}')
            port=$(echo "$line" | grep -oP '\d{1,5}/open' | grep -oP '\d{1,5}')
            service=$(echo "$line" | grep -i ssh)  # Check if the service is SSH

            # Only save the result if the service is confirmed to be SSH
            if [ ! -z "$service" ]; then
                echo "$team_number,$ip_address:$port" >> $output_file
            fi
        done
    fi
}

# Loop through all team numbers from start_team to end_team
for team_number in $(seq $start_team $end_team); do
    # Loop through all host types for each team
    for host_type in "${hosts[@]}"; do
        full_host="${host_type}.team${team_number}.isucdc.com"
        scan_host "$full_host" "$team_number"
    done
done

echo "Scan complete. Results saved to $output_file."
