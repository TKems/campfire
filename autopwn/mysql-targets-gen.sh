#!/bin/bash

# Global variables
start_team=1  # Adjust the starting team number here
end_team=39   # Adjust the ending team number here
output_file="mysql-targets.txt"
common_mysql_ports=(3306 33060 3307 1186 33062)  # Add other common MySQL ports as needed

# Function to perform the scan
scan_mysql_ports() {
    echo "Starting MySQL port scan from db.team${start_team}.isucdc.com to db.team${end_team}.isucdc.com"
    echo "Saving results to $output_file"
    
    # Clear the output file if it exists
    > $output_file
    
    # Loop through the team numbers
    for team in $(seq $start_team $end_team); do
        target="db.team${team}.isucdc.com"
        echo "Scanning $target..."

        # Scan the target for the specified MySQL ports
        nmap -p$(IFS=,; echo "${common_mysql_ports[*]}") --open $target | grep "Nmap scan report for" | awk '{print $5}' > temp_alive_hosts.txt

        # Check each alive host to see if the service is actually MySQL
        while IFS= read -r host; do
            echo "Verifying if $host is running MySQL..."
            
            # Perform service version detection to confirm MySQL for each common port
            for port in "${common_mysql_ports[@]}"; do
                nmap -p$port -sV $host | grep -i "mysql" > /dev/null
                
                if [ $? -eq 0 ]; then
                    echo "${team},${host}:${port}" >> $output_file
                fi
            done

        done < temp_alive_hosts.txt

        # Clean up temporary file
        rm temp_alive_hosts.txt
    done
    
    echo "Scan completed. MySQL services are saved in $output_file."
}

# Execute the function
scan_mysql_ports
