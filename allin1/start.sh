#!/bin/bash
set -e

# Export Guacamole environment variables
export GUACAMOLE_HOME=${GUACAMOLE_HOME:-/opt/guacamole}
export GUAC_DEFAULT_USER=${GUAC_DEFAULT_USER:-guacadmin}
export GUAC_DEFAULT_PASS=${GUAC_DEFAULT_PASS:-guacadmin}

# Ensure Guacamole directories exist
mkdir -p $GUACAMOLE_HOME
mkdir -p /root/.guacamole

# Start Tomcat with Guacamole in background
# The GUACAMOLE_HOME env var is used by start.sh for initialization
/opt/guacamole/bin/start.sh > /var/log/guacamole-startup.log 2>&1 &
sleep 3

# Start supervisord in foreground (PID 1)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n
