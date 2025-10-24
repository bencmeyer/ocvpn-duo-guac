#!/bin/bash
set -e

# Export Guacamole environment variables
export GUACAMOLE_HOME=${GUACAMOLE_HOME:-/opt/guacamole}
export GUAC_DEFAULT_USER=${GUAC_DEFAULT_USER:-guacadmin}
export GUAC_DEFAULT_PASS=${GUAC_DEFAULT_PASS:-guacadmin}

# Ensure Guacamole directories exist
mkdir -p $GUACAMOLE_HOME
mkdir -p /root/.guacamole

# Create user mapping BEFORE Guacamole starts
/opt/update-guac-admin.sh

# Start Tomcat with Guacamole in background
/opt/guacamole/bin/start.sh > /var/log/guacamole-startup.log 2>&1 &
GUAC_PID=$!
sleep 3

# After Guacamole generates guacamole.properties, append our auth settings
cat >> /root/.guacamole/guacamole.properties << 'EOF'

# XML Authentication Extension
auth-provider: xml
xml-root: /root/.guacamole/user-mapping.xml
EOF

# Give Tomcat a moment to reload
sleep 1

# Start supervisord in foreground (PID 1)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n
