#!/bin/bash

# Script to update Guacamole admin credentials
# This script modifies the user-mapping.xml to set custom admin credentials

GUAC_HOME="${GUACAMOLE_HOME:-/config/guacamole}"
USER_MAPPING="$GUAC_HOME/user-mapping.xml"

# Get credentials from environment or use defaults
ADMIN_USER="${GUACAMOLE_ADMIN_USER:-guacadmin}"
ADMIN_PASS="${GUACAMOLE_ADMIN_PASS:-guacadmin}"

# Only update if file exists
if [ -f "$USER_MAPPING" ]; then
    # Replace the default guacadmin user with custom credentials
    sed -i 's|<authorize username="guacadmin" password="guacadmin">|<authorize username="'"$ADMIN_USER"'" password="'"$ADMIN_PASS"'">|g' "$USER_MAPPING"
    
    # If user specified custom creds but defaults weren't in file, add them
    if ! grep -q "authorize username=\"$ADMIN_USER\"" "$USER_MAPPING"; then
        # Add a default blank connection for the admin user
        sed -i "/<user-mapping>/a\\
\\
    <!-- Admin user: configured via GUACAMOLE_ADMIN_USER and GUACAMOLE_ADMIN_PASS -->\\
    <authorize username=\"$ADMIN_USER\" password=\"$ADMIN_PASS\">\\
    </authorize>" "$USER_MAPPING"
    fi
    
    echo "✓ Updated Guacamole admin credentials: $ADMIN_USER"
else
    echo "! User mapping file not found at $USER_MAPPING"
fi
