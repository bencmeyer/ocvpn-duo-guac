#!/bin/bash

# Export Guacamole environment variables
export GUACAMOLE_HOME=${GUACAMOLE_HOME:-/opt/guacamole}
export GUAC_DEFAULT_USER=${GUAC_DEFAULT_USER:-guacadmin}
export GUAC_DEFAULT_PASS=${GUAC_DEFAULT_PASS:-guacadmin}

# Ensure Guacamole directories exist
mkdir -p $GUACAMOLE_HOME
mkdir -p /root/.guacamole

# Create user mapping XML file for XML authentication provider
echo "Creating XML authentication file for Guacamole admin user..."
cat > /root/.guacamole/user-mapping.xml << XMLEOF
<user-mapping>
    <authorize username="$GUAC_DEFAULT_USER" password="$GUAC_DEFAULT_PASS" 
               admin="true"
               create="true"
               delete="true"
               update="true"
               administer="true">
        <!-- System admin user with full Guacamole permissions -->
    </authorize>
</user-mapping>
XMLEOF

# Start supervisord in background
echo "Starting supervisord..."
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
SUPERVISOR_PID=$!

sleep 2

# Start Tomcat with Guacamole in background
echo "Starting Guacamole..."
/opt/guacamole/bin/start.sh > /var/log/guacamole-startup.log 2>&1 &
GUAC_PID=$!

sleep 5

# Configure Guacamole to use XML authentication
echo "Configuring XML authentication for Guacamole..."
cat >> /root/.guacamole/guacamole.properties << 'EOF'

# XML Authentication Provider
auth-provider: xml
xml-root: /root/.guacamole/user-mapping.xml
EOF

sleep 2

# Wait for Guacamole to start
echo "Waiting for Guacamole..."
for i in {1..60}; do
    if curl -s http://localhost:8080/guacamole/ > /dev/null 2>&1; then
        echo "✓ Guacamole is ready"
        break
    fi
    [ $((i % 10)) -eq 0 ] && echo "  Waiting... ($i/60)"
    sleep 1
done

echo ""
echo "✓ Services started:"
echo "  - Guacamole:   http://localhost:8080/guacamole/ ($GUAC_DEFAULT_USER / $GUAC_DEFAULT_PASS)"
echo "  - Dashboard:   http://localhost:9000"
echo ""
echo "Admin user configured with full permissions in Guacamole."
echo ""

# Keep supervisord running as PID 1
wait $SUPERVISOR_PID
