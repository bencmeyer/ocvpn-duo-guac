#!/bin/bash

# Script to set up Guacamole admin credentials
# Creates an XML authentication configuration with admin privileges

GUAC_HOME="${GUACAMOLE_HOME:-/root/.guacamole}"
mkdir -p "$GUAC_HOME"

# Get credentials from environment or use defaults
ADMIN_USER="${GUAC_DEFAULT_USER:-guacadmin}"
ADMIN_PASS="${GUAC_DEFAULT_PASS:-guacadmin}"

# Create user-mapping.xml for XML authentication backend with admin permissions
cat > "$GUAC_HOME/user-mapping.xml" << 'XMLEOF'
<user-mapping>
    <!-- System admin group -->
    <authorize group="system-admins">
    </authorize>
    
    <!-- Admin user - member of system-admins group -->
    <authorize username="ADMIN_USER_PLACEHOLDER" password="ADMIN_PASS_PLACEHOLDER" 
               group="system-admins"
               admin="true"
               create="true"
               delete="true"
               update="true"
               administer="true">
        <!-- System admin user can manage all connections and users -->
    </authorize>
</user-mapping>
XMLEOF

# Replace placeholders in user-mapping.xml
sed -i "s|ADMIN_USER_PLACEHOLDER|$ADMIN_USER|g" "$GUAC_HOME/user-mapping.xml"
sed -i "s|ADMIN_PASS_PLACEHOLDER|$ADMIN_PASS|g" "$GUAC_HOME/user-mapping.xml"

echo "✓ Created Guacamole user configuration: $ADMIN_USER"
echo "✓ Location: $GUAC_HOME/user-mapping.xml"
echo "✓ Admin privileges: enabled"
